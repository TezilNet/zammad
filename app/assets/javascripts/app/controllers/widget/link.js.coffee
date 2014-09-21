class App.WidgetLink extends App.Controller
  events:
    'click [data-type=add]': 'add',
    'click [data-type=remove]': 'remove',

  constructor: ->
    super
    @fetch()

  fetch: =>
    # fetch item on demand
    # get data
    @ajax(
      id:    'links_' + @object.id + '_' + @object_type,
      type:  'GET',
      url:   @apiPath + '/links',
      data:  {
        link_object:       @object_type,
        link_object_value: @object.id,
      }
      processData: true,
      success: (data, status, xhr) =>
        @links = data.links

        # load assets
        App.Collection.loadAssets( data.assets )

        @render()
    )

  render: =>

    list = {}
    for item in @links
      if !list[ item['link_type'] ]
        list[ item['link_type'] ] = []

      if item['link_object'] is 'Ticket'
        ticket = App.Ticket.fullLocal( item['link_object_value'] )
        if ticket.state.name is 'merged'
          ticket.css = 'merged'
        list[ item['link_type'] ].push ticket

    # insert data
    @html App.view('link/info')(
      links: list
    )

  remove: (e) =>
    e.preventDefault()
    link_type   = $(e.target).data('link-type')
    link_object_source = $(e.target).data('object')
    link_object_source_value = $(e.target).data('object-id')
    link_object_target = @object_type
    link_object_target_value = @object.id

    # get data
    @ajax(
      id:    'links_remove_' + @object.id + '_' + @object_type,
      type:  'GET',
      url:   @apiPath + '/links/remove',
      data:  {
        link_type:                 link_type,
        link_object_source:        link_object_source,
        link_object_source_value:  link_object_source_value,
        link_object_target:        link_object_target,
        link_object_target_value:  link_object_target_value,
      }
      processData: true,
      success: (data, status, xhr) =>
        @fetch()
    )

  add: (e) =>
    e.preventDefault()
    new App.LinkAdd(
      link_object:    @object_type,
      link_object_id: @object.id,
      object:         @object,
      parent:         @,
    )

class App.LinkAdd extends App.ControllerModal
  constructor: ->
    super
    @head   = 'Links'
    @button = true
    @cancel = true

    @html App.view('link/add')(
      link_object:    @link_object,
      link_object_id: @link_object_id,
      object:         @object,
    )
    @show()

  onSubmit: (e) =>
    e.preventDefault()
    params = @formParam(e.target)

    # get data
    @ajax(
      id:    'links_add_' + @object.id + '_' + @object_type,
      type:  'GET',
      url:   @apiPath + '/links/add',
      data:  {
        link_type:                params['link_type'],
        link_object_target:       'Ticket',
        link_object_target_value: @object.id,
        link_object_source:       'Ticket',
        link_object_source_number: params['ticket_number'],
      }
      processData: true,
      success: (data, status, xhr) =>
        @hide()
        @parent.fetch()
    )
