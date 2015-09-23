class EventManager

  @general =
    SUCCESS:                'SUCCESS'
    FAILURE:                'FAILURE'
    NOT_ALLOWED:            'NOT_ALLOWED'
    NOOP:                   'NOOP'

  @gamemanager =
    REGISTER_UPDATES:       'REGISTER_UPDATES'
    DEREGISTER_UPDATES:     'DEREISTER_UODATES'
    OBJECT_UPDATE:          'OBJECT_UPDATE'
    UPDATE_REGISTER_FAIL:   'UPDATE_REGISTER_FAIL'
    UPDATE_OBJECT_SUCCESS:  'UPDATE_OBJECT_SUCCESS'
    UPDATE_OBJECT_FAIL:     'UPDATE_OBJECT_FAIL'
    NO_SUCH_OBJECT:         'NO_SUCH_OBJECT'



  @event:(e...)->
    rv = []
    rv.push { e:e[key], o:e[key+1] or {} } for key in [0..e.length-1] by 2
    return rv

module.exports = EventManager

