class App.UserOrganizationAutocompletion extends App.Controller
  events:
    'hide.bs.dropdown .js-recipientDropdown': 'hideOrganisationMembers'
    'click .js-organisation':                 'showOrganisationMembers'
    'click .js-back':                         'hideOrganisationMembers'
    'click .js-user':                         'selectUser'
    'click .js-user-new':                     'newUser'

  constructor: (params) ->
    super

    @key = Math.floor( Math.random() * 999999 ).toString()

    if !@attribute.source
      @attribute.source = @apiPath + '/search_user_org'
    @build()

  element: =>
    @el

  selectUser: (e) ->
    userId = $(e.target).parents('.recipientList-entry').data('user-id')
    if !userId
      userId = $(e.target).data('user-id')

    @el.find('[name="' + @attribute.name + '"]').val( userId ).trigger('change')

  setUser: ->
    userId = @el.find('[name="' + @attribute.name + '"]').val()
    return if !userId
    return if !App.User.exists(userId)
    user = App.User.find(userId)
    name = user.displayName()
    if user.email
      name += " <#{user.email}>"
    @el.find('[name="' + @attribute.name + '_completion"]').val( name ).trigger('change')

    if @callback
      @callback(userId)

  buildOrganizationItem: (organization) =>
    App.view('generic/user_search/item_organization')(
      organization: organization
    )

  buildOrganizationMembers: (organization) =>
    organizationMemebers = $( App.view('generic/user_search/item_organization_members')(
      organization: organization
    ) )
    for userId in organization.member_ids
      user = App.User.fullLocal(userId)
      organizationMemebers.append( @buildUserItem(user) )

  buildUserItem: (user) =>
    App.view('generic/user_search/item_user')(
      user: user
    )

  buildUserNew: =>
    App.view('generic/user_search/new_user')()

  build: =>
    @el.html App.view('generic/user_search/input')(
      attribute: @attribute
    )
    @el.find('[name="' + @attribute.name + '"]').on(
      'change',
      (e) =>
        @setUser()
    )

    @el.find('[name="' + @attribute.name + '_completion"]').on(
      'keyup',
      (e) =>
        item = $(e.target).val()

        #@log('CC', e.keyCode, item)

        # clean input field on ESC
        if e.keyCode is 27
          $(e.target).val('')
          item = ''

        # ignore arrow keys
        return if e.keyCode is 37
        return if e.keyCode is 38
        return if e.keyCode is 39
        return if e.keyCode is 40

        # ignore shift
        return if e.keyCode is 16

        # ignore ctrl
        return if e.keyCode is 17

        # ignore alt
        return if e.keyCode is 18

        # hide dropdown
        @el.find('.recipientList').html('')
        @el.find('.recipientList-organisationMembers').remove()
        if !item && !@attribute.disableCreateUser
          @el.find('.recipientList').append( @buildUserNew() )

        # show dropdown
        if item && ( !@attribute.minLengt || @attribute.minLengt <= item.length )
          execute = => @searchUser(item)
          @delay( execute, 400, 'userSearch' )
    )

  searchUser: (term) =>

    @ajax(
      id:    'searchUser' + @key
      type:  'GET'
      url:   @attribute.source
      data:
        query: term
      processData: true
      success: (data, status, xhr) =>
        # load assets
        App.Collection.loadAssets( data.assets )

        # build markup
        for item in data.result

          # organization
          if item.type is 'Organization'
            organization = App.Organization.fullLocal( item.id )
            @el.find('.recipientList').append( @buildOrganizationItem(organization) )

            # users of organization
            if organization.member_ids
              @el.find('.dropdown-menu').append( @buildOrganizationMembers(organization) )

          # users
          if item.type is 'User'
            user = App.User.fullLocal( item.id )
            @el.find('.recipientList').append( @buildUserItem(user) )

        if !@attribute.disableCreateUser
          @el.find('.recipientList').append( @buildUserNew() )
    )

  showOrganisationMembers: (e) =>
    e.stopPropagation()

    listEntry = $(e.currentTarget)
    organisationId = listEntry.data('organisation-id')

    @recipientList = @$('.recipientList')
    @organisationList = @$("##{ organisationId }")

    # move organisation-list to the right and slide it in

    $.Velocity.hook(@organisationList, 'translateX', '100%')
    @organisationList.removeClass('hide')

    @organisationList.velocity
      properties:
        translateX: 0
      options:
        speed: 300

    # fade out list
    @recipientList.velocity
      properties:
        translateX: '-100%'
      options:
        speed: 300
        complete: => @recipientList.height(@organisationList.height())

  hideOrganisationMembers: (e) =>
    e && e.stopPropagation()

    return if !@organisationList

    # fade list back in
    @recipientList.velocity
      properties:
        translateX: 0
      options:
        speed: 300

    # reset list height

    @recipientList.height('')

    # slide out organisation-list and hide it
    @organisationList.velocity
      properties:
        translateX: '100%'
      options:
        speed: 300
        complete: => @organisationList.addClass('hide')

  newUser: (e) =>
    e.preventDefault()
    new UserNew(
      parent: @
    )

class UserNew extends App.ControllerModal
  constructor: ->
    super
    @head   = 'New User'
    @cancel = true
    @button = true

    controller = new App.ControllerForm(
      model:      App.User
      screen:     'edit'
      autofocus:  true
    )

    @el = controller.form

    @show()

  onSubmit: (e) ->

    e.preventDefault()
    params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !params.login && params.email
      params.login = params.email

    # find role_id
    if !params.role_ids || _.isEmpty( params.role_ids )
      role = App.Role.findByAttribute( 'name', 'Customer' )
      params.role_ids = role.id
    @log 'notice', 'updateAttributes', params

    user = new App.User
    user.load(params)

    errors = user.validate()
    if errors
      @log 'error', errors
      @formValidate( form: e.target, errors: errors )
      return

    # save user
    ui = @
    user.save(
      done: ->

        # force to reload object
        callbackReload = (user) ->
          ui.parent.el.find('[name=customer_id]').val( user.id ).trigger('change')

          # start customer info controller
          ui.hide()
        App.User.full( @id, callbackReload , true )

      fail: ->
        ui.hide()
    )