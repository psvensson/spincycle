define(['ractive'], (Ractive) =>

  mdldialog = Ractive.extend({
    components: {}
    isolated: false

    data: () ->
      type: ''
      guid: ''
      currentDialogCallback: ''
      onSelectedItem: (e)=>
        console.log 'mdldialog selected callback'
        cb = @get('currentDialogCallback')
        if cb then cb(e.context)
        dialog = @find('#'+@get('guid')+'-dialog')
        dialog.close()

        
    oninit: () ->
      guid = @_guid
      @set('guid', guid)
      window.subscribe 'modeldialogopen',(args) =>
        cb = args.cb
        @set('type', args.type)
        console.log '--on dialog open'
        @set('currentDialogCallback', cb)

        dialog = document.getElementById(guid+'-dialog')
        console.log 'guid is '+guid
        console.dir @el
        dialog.showModal()


    oncomplete: ()->

    onClose : ()->
      dialog = @find('#'+@get('guid')+'-dialog')
      dialog.close()


    template: """
      <dialog class="mdl-dialog" id='{{guid}}-dialog'>
        <h4 class="mdl-dialog__title">Select {{type}}</h4>
        <div class="mdl-dialog__content">
          <p>
          {{#type}}
            <modelspinlist type='{{type}}' onSelected='{{onSelectedItem}}'></modelspinlist>
          {{/}}
          </p>
        </div>
        <div class="mdl-dialog__actions">
          <button type="button" class="mdl-button" on-click='onClose()'>Close</button>
        </div>
      </dialog>
      """
  })
  console.log 'mdldialog defined'
  return mdldialog
)

