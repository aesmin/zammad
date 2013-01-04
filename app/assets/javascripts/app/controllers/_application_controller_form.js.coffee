class App.ControllerForm extends App.Controller
  constructor: (params) ->
    for key, value of params
      @[key] = value
    @attribute_count = 0

    @form = @formGen()
#    @log 'form', @form
    if @el
      @el.prepend( @form )

  html: =>
    @form.html()

  formGen: ->
    App.Log.log 'ControllerForm', 'debug', 'formGen', @model.configure_attributes

    fieldset = $('<fieldset>')

    for attribute_clean in @model.configure_attributes
      attribute = _.clone( attribute_clean )

      if !attribute.readonly && ( !@required || @required && attribute[@required] )

        @attribute_count = @attribute_count + 1

        # add item
        item = @formGenItem( attribute, @model.className, fieldset )
        item.appendTo(fieldset)

        # if password, add confirm password item
        if attribute.type is 'password'

          # get existing value, if exists
          if @params
            if attribute.name of @params
              attribute.value = @params[attribute.name]

          # rename display and name to _confirm
          attribute.display = attribute.display + ' (confirm)'
          attribute.name = attribute.name + '_confirm';
          item = @formGenItem( attribute, @model.className, fieldset )
          item.appendTo(fieldset)

    # return form
    return fieldset

  ###

  # input text field with max. 100 size
  attribute_config = {
    name:     'subject',
    display:  'Subject',
    tag:      'input',
    type:     'text',
    limit:    100,
    null:     false,
    default:  defaults['subject'],
    class:    'span7'
  }

  # colection as relation with auto completion
  attribute_config = {
    name:           'customer_id',
    display:        'Customer',
    tag:            'autocompletion',
    # auto completion params, endpoints, ui,...
    type:           'text',
    limit:          100,
    null:           false,
    relation:       'User',
    autocapitalize: false,
    help:           'Select the customer of the Ticket or create one.',
    link:           '<a href="" class="customer_new">&raquo;</a>',
    callback:       @userInfo
    class:          'span7',
  }

  # colection as relation
  attribute_config = {
    name:       'ticket_priority_id',
    display:    'Priority',
    tag:        'select',
    multiple:   false,
    null:       false,
    relation:   'TicketPriority',
    default:    defaults['ticket_priority_id'],
    translate:  true,
    class:      'medium'
  }

  ###

  formGenItem: (attribute_config, classname, form ) ->
    attribute = _.clone( attribute_config )

    # create item id
    attribute.id = classname + '_' + attribute.name

    # set autofocus
    if @autofocus && @attribute_count is 1
      attribute.autofocus = 'autofocus'

    # set required option
    if !attribute.null
      attribute.required = 'required'
    else
      attribute.required = ''

    # set multible option
    if attribute.multiple
      attribute.multiple = 'multiple'
    else
      attribute.multiple = ''

    # set autocapitalize option
    if attribute.autocapitalize is undefined || attribute.autocapitalize
      attribute.autocapitalize = ''
    else
      attribute.autocapitalize = 'autocapitalize="off"'

    # set autocomplete option
    if attribute.autocomplete is undefined
      attribute.autocomplete = ''
    else
      attribute.autocomplete = 'autocomplete="' + attribute.autocomplete + '"'

    # set value
    if @params
      if attribute.name of @params
        attribute.value = @params[attribute.name]

    # set default value
    else
      if 'default' of attribute
        attribute.value = attribute.default
      else
        attribute.value = ''

    App.Log.log 'ControllerForm', 'debug', 'formGenItem-before', attribute


    # build options list based on config
    @_getConfigOptionList( attribute )

    # build options list based on relation
    @_getRelationOptionList( attribute )

    # add null selection if needed
    @_addNullOption( attribute )

    # sort attribute.options
    @_sortOptions( attribute )

    # finde selected/checked item of list
    @_selectedOptions( attribute )

    # filter attributes
    @_filterOption( attribute )

    if attribute.tag is 'boolean'

      # build options list
      if _.isEmpty(attribute.options)
        attribute.options = [
          { name: 'active', value: true } 
          { name: 'inactive', value: false } 
        ]

      # update boolean types
      for record in attribute.options
        record.value = '{boolean}::' + record.value

      # finde selected item of list
      for record in attribute.options
        if record.value is '{boolean}::' + attribute.value
          record.selected = 'selected'

      # return item
      item = $( App.view('generic/select')( attribute: attribute ) )

    # select
    else if attribute.tag is 'select'
      item = $( App.view('generic/select')( attribute: attribute ) )

    # select
    else if attribute.tag is 'input_select'
      item = $('<div class="input_select"></div>')

      # select shown attributes
      loopData = {}
      if @params && @params[ attribute.name ]
        loopData = @params[ attribute.name ]
      loopData[''] = ''

      # show each attribote
      counter = 0
      for key of loopData
        counter =+ 1
#        @log 'kkk', key, loopData[ key ]

        # clone to keep it untouched for next loop
        select = _.clone( attribute )
        input  = _.clone( attribute )

        # set field ids - not needed in this case
        select.id = ''
        input.id  = ''

        # rename to be able to identify this option later
        select.name = '{input_select}::' + select.name
        input.name  = '{input_select}::' + input.name

        # set sub attributes
        for keysub of attribute.select
          select[keysub] = attribute.select[keysub]
        for keysub of attribute.input
          input[keysub] = attribute.input[keysub]

        # set hide for + options
        itemClass = ''
        if key is ''
          itemClass = 'hide'
          select['nulloption'] = true

        # set selected value
        select.value = key
        input.value  = loopData[ key ]

        # build options list based on config
        @_getConfigOptionList( select )

        # build options list based on relation
        @_getRelationOptionList( select )

        # add null selection if needed
        @_addNullOption( select )

        # sort attribute.options
        @_sortOptions( select )

        # finde selected/checked item of list
        @_selectedOptions( select )

        pearItem = $("<div class=" + itemClass + "></div>")
        pearItem.append $( App.view('generic/select')( attribute: select ) )
        pearItem.append $( App.view('generic/input')( attribute: input ) )
        itemRemote = $('<a href="#" class="input_select_remove icon-minus"></a>')
        itemRemote.bind('click', (e) ->
          e.preventDefault()
          $(@).parent().remove()
        )
        pearItem.append( itemRemote )
        item.append( pearItem )

        if key is ''
          itemAdd = $('<div class="add"><a href="#" class="icon-plus"></a></div>')
          itemAdd.bind('click', (e) ->
            e.preventDefault()

            # copy
            newElement = $(@).prev().clone()
            newElement.removeClass('hide')

            # bind on remove
            newElement.find('.input_select_remove').bind('click', (e) ->
              e.preventDefault()
              $(@).parent().remove()
            )

            # prepend
            $(@).parent().find('.add').before( newElement )
          )
          item.append( itemAdd )

    # checkbox
    else if attribute.tag is 'checkbox'
      item = $( App.view('generic/checkbox')( attribute: attribute ) )

    # radio
    else if attribute.tag is 'radio'
      item = App.view('generic/radio')( attribute: attribute )

    # textarea
    else if attribute.tag is 'textarea'
      item = $( App.view('generic/textarea')( attribute: attribute ) )
      if attribute.upload
        fileUploaderId = 'file-uploader-' + new Date().getTime() + '-' + Math.floor( Math.random() * 99999 )
        item.after('<div class="' + attribute.class + '" id="' + fileUploaderId + '"></div>')

        # add file uploader
        u = =>
          @el.find('#' + fileUploaderId ).fineUploader(
            request:
              endpoint: '/api/ticket_attachment_new'
              params:
                form_id: @form_id
            text:
              uploadButton: '<i class="icon-attachment"></i>'
            template: '<div class="qq-uploader">' +
                        '<pre class="btn qq-upload-icon qq-upload-drop-area"><span>{dragZoneText}</span></pre>' +
                        '<div class="btn qq-upload-icon qq-upload-button pull-right" style="">{uploadButtonText}</div>' +
                        '<ul class="qq-upload-list span5" style="margin-top: 10px;"></ul>' +
                      '</div>',
            classes:
              success: ''
              fail:    ''
            debug: false
          )
        @delay( u, 80 )

    # tag
    else if attribute.tag is 'tag'
      item = $( App.view('generic/input')( attribute: attribute ) )
      a = =>
        siteUpdate = (reorder) =>
          container = document.getElementById( attribute.id + "_tagsinput" )
          if reorder
            $('#' + attribute.id + "_tagsinput" ).height( 20 )
          height = container.scrollHeight
          $('#' + attribute.id + "_tagsinput" ).height( height - 16 )

        onAddTag = =>
          siteUpdate()

        onRemoveTag = =>
          siteUpdate(true)

        $('#' + attribute.id + '_tagsinput').remove()
        w = $('#' + attribute.id).width()
        h = $('#' + attribute.id).height()
        $('#' + attribute.id).tagsInput(
          width: w + 'px'
#          height: (h + 30 )+ 'px'
          onAddTag:    onAddTag
          onRemoveTag: onRemoveTag
        )
        siteUpdate(true)

      @delay( a, 80 )


    # autocompletion
    else if attribute.tag is 'autocompletion'
      item = $( App.view('generic/autocompletion')( attribute: attribute ) )

      a = =>
        @local_attribute = '#' + attribute.id
        @local_attribute_full = '#' + attribute.id + '_autocompletion'
        @callback = attribute.callback

        b = (event, key) =>

          # set html form attribute
          $(@local_attribute).val(key)

          # call calback
          if @callback
            params = App.ControllerForm.params(form)
            @callback( params )
        ###
        $(@local_attribute_full).tagsInput(
          autocomplete_url: '/users/search',
          height: '30px',
          width: '530px',
          auto: {
            source: '/users/search',
            minLength: 2,
            select: ( event, ui ) =>
              @log 'selected', event, ui
              b(event, ui.item.id)
          }
        )
        ###
#        @log '111111', @local_attribute_full, item
        $(@local_attribute_full).autocomplete(
          source: '/api/users/search',
          minLength: 2,
          select: ( event, ui ) =>
#            @log 'selected', event, ui
            b(event, ui.item.id)
        )
      @delay( a, 180 )

    # input
    else
      item = $( App.view('generic/input')( attribute: attribute ) )

    if attribute.onchange
#      @log 'on change', attribute.name
      if typeof attribute.onchange is 'function'
        attribute.onchange(attribute)
      else
        for i of attribute.onchange
          a = i.split(/__/)
          if a[1]
            if a[0] is attribute.name
#              @log 'aaa', i, a[0], attribute.id
              @attribute = attribute
              @classname = classname
              @attributes_clean = attributes_clean
              @change = a
              b = =>
#                console.log 'aaa', @attribute
                attribute = @attribute
                change = @change
                classname = @classname
                attributes_clean = @attributes_clean
                ui = @
                $('#' + @attribute.id).bind('change', ->
                  ui.log 'change', @, attribute, change
                  ui.log change[0] + ' has changed - changing ' + change[1]

                  item = $( ui.formGenItem(attribute, classname, attributes_clean) )
                  ui.log item, classname
                )
              @delay(b, 100)
#            if attribute.onchange[]

    ui = @
#    item.bind('focus', ->
#      ui.log 'focus', attribute
#    );
    item.bind('change', ->
      if ui.form_data
        params = App.ControllerForm.params(@)
        for i of ui.form_data
          a = i.split(/__/)
          if a[1] && a[0] is attribute.name
            newListAttribute  = i
            changedAttribute  = a[0]
            toChangeAttribute = a[1]

            # get new option list
            newListAttributes = ui['form_data'][newListAttribute][ params['group_id'] ]

            # find element to replace
            for item in ui.model.configure_attributes
              if item.name is toChangeAttribute
                item.display = false
                item['filter'][toChangeAttribute] = newListAttributes
                if params[changedAttribute]
                  item.default = params[toChangeAttribute]
                if !item.default
                  delete item['default']
                newElement = ui.formGenItem( item, classname, form )

            # replace new option list
            form.find('[name="' + toChangeAttribute + '"]').replaceWith( newElement )
    )

    if !attribute.display
      return item
    else
      a = $( App.view('generic/attribute')(
        attribute: attribute,
        item:      '',
      ) )
      a.find('.controls').prepend( item )
      return a

  # sort attribute.options
  _sortOptions: (attribute) ->

    return if !attribute.options

    options_by_name = []
    for i in attribute.options
      options_by_name.push i['name'].toString().toLowerCase()
    options_by_name = options_by_name.sort()

    options_new = []
    options_new_used = {}
    for i in options_by_name
      for ii, vv in attribute.options
        if !options_new_used[ ii['value'] ] && i.toString().toLowerCase() is ii['name'].toString().toLowerCase()
          options_new_used[ ii['value'] ] = 1
          options_new.push ii
    attribute.options = options_new


  _addNullOption: (attribute) ->
    return if !attribute.options
    return if !attribute.nulloption
    attribute.options[''] = '-'
    attribute.options.push {
      name:  '-',
      value: '',
    }


  _getConfigOptionList: (attribute) ->
    return if !attribute.options
    selection = attribute.options
    attribute.options = []
    for key, value of selection
      name_new = value
      if attribute.translate
        name_new = App.i18n.translateInline( name_new )
      attribute.options.push {
        name:  name_new,
        value: key,
      }


  _getRelationOptionList: (attribute) ->

    # build options list based on relation
    return if !attribute.relation
    return if !App[attribute.relation]

    attribute.options = []

    list = []
    if attribute.filter
      App.Log.log 'ControllerForm', 'debug', '_getRelationOptionList:filter', attribute.filter

      # function based filter
      if typeof attribute.filter is 'function'
        App.Log.log 'ControllerForm', 'debug', '_getRelationOptionList:filter-function'

        all = App[attribute.relation].all()
        list = attribute.filter( all, 'collection' )

      # data based filter
      else if attribute.filter[ attribute.name ]
        filter = attribute.filter[ attribute.name ]

        App.Log.log 'ControllerForm', 'debug', '_getRelationOptionList:filter-data', filter

        # check all records
        for record in App[attribute.relation].all()

          # check all filter attributes
          for key in filter

            # check all filter values as array
            # if it's matching, use it for selection
            if record['id'] is key
              list.push record

      # no data filter matched
      else
        App.Log.log 'ControllerForm', 'debug', '_getRelationOptionList:filter-data no filter matched'
        list = App[attribute.relation].all()
    else
      App.Log.log 'ControllerForm', 'debug', '_getRelationOptionList:filter-no filter defined'
      list = App[attribute.relation].all()

    App.Log.log 'ControllerForm', 'debug', '_getRelationOptionList', attribute, list

    # build options list
    @_buildOptionList( list, attribute )


  # build options list
  _buildOptionList: (list, attribute) ->

    for item in list

      # if active or if active doesn't exist
      if item.active || !( 'active' of item )
        name_new = '?'
        if item.displayName
          name_new = item.displayName()
        if attribute.translate
          name_new = App.i18n.translateInline(name_new)
        attribute.options.push {
          name:  name_new,
          value: item.id,
          note:  item.note,
        }

  # execute filter
  _filterOption: (attribute) ->
    return if !attribute.filter
    return if !attribute.options

    return if typeof attribute.filter isnt 'function'
    App.Log.log 'ControllerForm', 'debug', '_filterOption:filter-function'

    attribute.options = attribute.filter( attribute.options, attribute )

  # set selected attributes
  _selectedOptions: (attribute) ->

    return if !attribute.options

    for record in attribute.options
      if typeof attribute.value is 'string' || typeof attribute.value is 'number' || typeof attribute.value is 'boolean'

        # if name or value is matching
        if record.value.toString() is attribute.value.toString() || record.name.toString() is attribute.value.toString()
          record.selected = 'selected'
          record.checked = 'checked'
#          if record.name.toString() is attribute.value.toString()
#            record.selected = 'selected'
#            record.checked = 'checked'

      else if ( attribute.value && record.value && _.include(attribute.value, record.value) ) || ( attribute.value && record.name && _.include(attribute.value, record.name) )
        record.selected = 'selected'
        record.checked = 'checked'

  validate: (params) ->
    App.Model.validate(
      model: @model,
      params: params,
    )

  # get all params of the form
  @params: (form) ->
    param = {}

    # find form based on sub elements
    if $(form).children()[0]
      form = $(form).children().parents('form')

    # find form based on parents next <form>
    else if $(form).parents('form')[0]
      form = $(form).parents('form')

    # find form based on parents next <form>, not really good!
    else if $(form).parents().find('form')[0]
      form = $(form).parents().find('form')
    else
      App.Log.log 'ControllerForm', 'error', 'no form found!', form

    array = form.serializeArray()
    for key in array
      if param[key.name]
        if typeof param[key.name] is 'string'
          param[key.name] = [ param[key.name], key.value]
        else
          param[key.name].push key.value
      else

        # check boolean
        attributeType = key.value.split '::'
        if attributeType[0] is '{boolean}'
          if attributeType[1] is 'true'
            key.value = true
          else
            key.value = false
#        else if attributeType[0] is '{boolean}'

        param[key.name] = key.value

    # check {input_select}
    inputSelectObject = {}
    for key of param
      attributeType = key.split '::'
      name = attributeType[1]
#      console.log 'split', key, attributeType, param[ name ]
      if attributeType[0] is '{input_select}' && !param[ name ]

        # array need to be converted
        inputSelectData = param[ key ]
        inputSelectObject[ name ] = {}
        for x in [0..inputSelectData.length] by 2
#          console.log 'for by 111', x, inputSelectData, inputSelectData[x], inputSelectData[ x + 1 ]
          if inputSelectData[ x ]
            inputSelectObject[ name ][ inputSelectData[x] ] = inputSelectData[ x + 1 ]

        # remove {input_select} items
        delete param[ key ]

    # set new {input_select} items
    for key of inputSelectObject
      param[ key ] = inputSelectObject[ key ]

    App.Log.log 'ControllerForm', 'notice', 'formParam', form, param
    return param

  @formId: ->
    formId = new Date().getTime() + Math.floor( Math.random() * 99999 )
    formId.toString().substr formId.toString().length-9, 9

  @disable: (form) ->
    App.Log.log 'ControllerForm', 'notice', 'disable...', $(form.target).parent()
    $(form.target).parent().find('button').attr('disabled', true)
    $(form.target).parent().find('[type="submit"]').attr('disabled', true)
    $(form.target).parent().find('[type="reset"]').attr('disabled', true)


  @enable: (form) ->
    App.Log.log 'ControllerForm', 'notice', 'enable...', $(form.target).parent()
    $(form.target).parent().find('button').attr('disabled', false)
    $(form.target).parent().find('[type="submit"]').attr('disabled', false)
    $(form.target).parent().find('[type="reset"]').attr('disabled', false)

  @validate: (data) ->

    # remove all errors
    $(data.form).parents().find('.error').removeClass('error')
    $(data.form).parents().find('.help-inline').html('')

    # show new errors
    for key, msg of data.errors
      $(data.form).parents().find('[name*="' + key + '"]').parents('div .control-group').addClass('error')
      $(data.form).parents().find('[name*="' + key + '"]').parent().find('.help-inline').html(msg)

    # set autofocus
    $(data.form).parents().find('.error').find('input, textarea').first().focus()

#    # enable form again
#    if $(data.form).parents().find('.error').html()
#      @formEnable(data.form)

