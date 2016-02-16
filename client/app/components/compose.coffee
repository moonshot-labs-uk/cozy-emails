{div, section, h3, a, i, textarea, form, label} = React.DOM
{span, ul, li, input} = React.DOM

classer = React.addons.classSet

ComposeEditor  = require './compose_editor'
ComposeToolbox = require './compose_toolbox'
FilePicker     = require './file_picker'
MailsInput     = require './mails_input'

AccountPicker = require './account_picker'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'

{ComposeActions, Tooltips} = require '../constants/app_constants'

MessageUtils = require '../utils/message_utils'


LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

RouterMixin = require '../mixins/router_mixin'


# Component that allows the user to write emails.
module.exports = Compose = React.createClass
    displayName: 'Compose'


    mixins: [
        RouterMixin,
        React.addons.LinkedStateMixin # two-way data binding
    ]


    propTypes:
        selectedAccountID:    React.PropTypes.string.isRequired
        selectedAccountLogin: React.PropTypes.string.isRequired
        layout:               React.PropTypes.string
        accounts:             React.PropTypes.object.isRequired
        message:              React.PropTypes.object
        action:               React.PropTypes.string
        callback:             React.PropTypes.func
        onCancel:             React.PropTypes.func
        settings:             React.PropTypes.object.isRequired
        useIntents:           React.PropTypes.bool.isRequired


    getDefaultProps: ->
        layout: 'full'

    shouldComponentUpdate: (nextProps, nextState) ->
        !!nextProps.accounts

    render: ->
        closeUrl = @buildClosePanelUrl @props.layout

        classLabel = 'compose-label'
        classInput = 'compose-input'
        classCc    = if @state.ccShown  then ' shown ' else ''
        classBcc   = if @state.bccShown then ' shown ' else ''

        focusEditor = Array.isArray(@state.to) and
            @state.to.length > 0 and
            @state.subject isnt ''

        section
            className: classer
                compose: true
                panel:   @props.layout is 'full'
            'aria-expanded': true,

            form className: 'form-compose', method: 'POST',
                div className: 'form-group account',
                    label
                        htmlFor: 'compose-from',
                        className: classLabel,
                        t "compose from"
                    AccountPicker
                        accounts: @props.accounts
                        valueLink: @linkState 'accountID'
                div className: 'clearfix', null

                div className: classInput,
                    div
                        className: 'btn-toolbar compose-toggle',
                        role: 'toolbar',
                            div null
                                a
                                    className: 'compose-toggle-cc',
                                    onClick: @onToggleCc,
                                    t 'compose toggle cc'
                                a
                                    className: 'compose-toggle-bcc',
                                    onClick: @onToggleBcc,
                                    t 'compose toggle bcc'

                MailsInput
                    id: 'compose-to'
                    valueLink: @linkState 'to'
                    label: t 'compose to'
                    ref: 'to'

                MailsInput
                    id: 'compose-cc'
                    className: 'compose-cc' + classCc
                    valueLink: @linkState 'cc'
                    label: t 'compose cc'
                    placeholder: t 'compose cc help'
                    ref: 'cc'

                MailsInput
                    id: 'compose-bcc'
                    className: 'compose-bcc' + classBcc
                    valueLink: @linkState 'bcc'
                    label: t 'compose bcc'
                    placeholder: t 'compose bcc help'
                    ref: 'bcc'

                div className: 'form-group',
                    div className: classInput,
                        input
                            id: 'compose-subject'
                            name: 'compose-subject'
                            ref: 'subject'
                            valueLink: @linkState 'subject'
                            type: 'text'
                            className: 'form-control compose-subject'
                            placeholder: t "compose subject help"

                div className: 'compose-content',
                    ComposeEditor
                        id                : 'compose-editor'
                        messageID         : @props.message?.get 'id'
                        html              : @linkState('html')
                        text              : @linkState('text')
                        accounts          : @props.accounts
                        accountID         : @state.accountID
                        settings          : @props.settings
                        onSend            : @sendMessage
                        composeInHTML     : @state.composeInHTML
                        focus             : focusEditor
                        ref               : 'editor'
                        getPicker         : @getPicker
                        useIntents        : @props.useIntents

                div className: 'attachements',
                    FilePicker
                        className: ''
                        editable: true
                        valueLink: @linkState 'attachments'
                        ref: 'attachments'

                ComposeToolbox
                    onSend    : @sendMessage
                    onDelete  : @onDelete
                    onDraft   : @saveDraft
                    onCancel  : @onCancel
                    canDelete : @props.message?

                div className: 'clearfix', null


    # If we are answering to a message, canceling should bring back to
    # this message.
    # The message URL requires many information: account ID, mailbox ID,
    # conversation ID and message ID. These infor are collected via current
    # selection and message information.
    finalRedirect: ->
        if @props.inReplyTo?
            conversationID = @props.inReplyTo.get('conversationID')
            accountID = @props.inReplyTo.get('accountID')
            messageID = @props.inReplyTo.get('id')
            mailboxes = Object.keys @props.inReplyTo.get 'mailboxIDs'
            mailboxID = AccountStore.pickBestBox accountID, mailboxes

            @redirect
                firstPanel:
                    action: 'account.mailbox.messages'
                    parameters: {accountID, mailboxID}

                secondPanel:
                    action: 'conversation'
                    parameters: {conversationID, messageID}

        # Else it should bring to the default view
        else
            @redirect
                direction: 'first'
                action: 'default'
                fullWidth: true

    # Cancel brings back to default view. If it's while replying to a message,
    # it brings back to this message.
    onCancel: (event) ->
        event.preventDefault()

        # Action after cancelation: call @props.onCancel
        # or navigate to message list.
        if @props.onCancel?
            @props.onCancel()
        else
            @finalRedirect()


    componentDidMount: ->
        # Initialize @state
        # with values from server
        if @props.settings.get 'autosaveDraft'
            @saveDraft()

        # scroll compose window into view
        @getDOMNode().scrollIntoView()

        # Focus
        if not Array.isArray(@state.to) or @state.to.length is 0
            setTimeout ->
                document.getElementById('compose-to')?.focus()
            , 10
        else if @props.inReplyTo?
            document.getElementById('compose-editor')?.focus()

    componentDidUpdate: ->
        # focus
        switch @state.focus
            when 'cc'
                setTimeout ->
                    document.getElementById('compose-cc').focus()
                , 0
                @setState focus: ''

            when 'bcc'
                setTimeout ->
                    document.getElementById('compose-bcc').focus()
                , 0
                @setState focus: ''

    componentWillUnmount: ->
        # delete draft
        doDelete = =>
            window.setTimeout =>
                LayoutActionCreator.hideModal()
                messageID = @state.id
                MessageActionCreator.delete {messageID, silent, isDraft: true, inReplyTo: @props.inReplyTo}
            , 5

        # save draft one last time
        doSave = =>
            if @state.originalConversationID?
                # save one last time the draft, adding the conversationID
                message =
                    id            : @state.id
                    accountID     : @state.accountID
                    mailboxIDs    : @state.mailboxIDs
                    from          : @state.from
                    to            : @state.to
                    cc            : @state.cc
                    bcc           : @state.bcc
                    subject       : @state.subject
                    isDraft       : true
                    attachments   : @state.attachments
                    inReplyTo     : @state.inReplyTo
                    references    : @state.references
                    text          : @state.text
                    html          : @state.html
                    conversationID: @state.originalConversationID
                MessageActionCreator.send message, (error, message) ->
                    if error? or not message?
                        msg = "#{t "message action draft ko"} #{error}"
                        LayoutActionCreator.alertError msg
                    else
                        msg = "#{t "message action draft ok"}"
                        LayoutActionCreator.notify msg, autoclose: true
                        if message.conversationID?
                            # reload conversation to update its length
                            cid = message.conversationID
                            MessageActionCreator.fetchConversation cid
            else


        # If message has not been sent, ask if we should keep it or not
        #  - if yes, and the draft belongs to a conversation, add the
        #    conversationID and save the draft
        #  - if no, delete the draft
        if not @state.isDeleted and @state.isDraft and @state.id?

            if @state.composeInHTML
                newContent = MessageUtils.cleanReplyText(@state.html).replace /\s/gim, ''
                oldContent = MessageUtils.cleanReplyText(@state.initHtml).replace /\s/gim, ''
                updated = newContent isnt oldContent
            else
                updated = @state.text isnt @state.initText

            # if draft has not been updated, delete without asking confirmation
            silent = @state.isNew and not updated
            if silent
                doDelete()
            else
                # we need a timeout because of React's components life cycle
                setTimeout ->
                    # display a modal asking if we should keep or delete the draft
                    modal =
                        title       : t 'app confirm delete'
                        subtitle    : t 'compose confirm keep draft'
                        closeModal  : ->
                            doSave()
                            LayoutActionCreator.hideModal()
                        closeLabel  : t 'compose confirm draft keep'
                        actionLabel : t 'compose confirm draft delete'
                        action      : doDelete
                    LayoutActionCreator.displayModal modal
                , 0


    getInitialState: ->

        # edition of an existing draft
        if message = @props.message
            state =
                composeInHTML: @props.settings.get 'composeInHTML'
                isNew: false
            if (not message.get('html')?) and message.get('text')
                state.composeInHTML = false

            # TODO : smarter ?
            state[key] = value for key, value of message.toJS()
            # we want the immutable attachments
            state.attachments = message.get 'attachments'

        # new draft
        else
            account = @props.accounts.get @props.selectedAccountID
            state = MessageUtils.makeReplyMessage(
                account.get('login'),
                @props.inReplyTo,
                @props.action,
                @props.settings.get('composeInHTML'),
                account.get('signature')
            )
            state.isNew = true
            state.accountID ?= @props.selectedAccountID

        state.isDraft  = true

        state.ccShown  = Array.isArray(state.cc) and state.cc.length > 0
        state.bccShown = Array.isArray(state.bcc) and state.bcc.length > 0
        # save initial message content, to don't ask confirmation if
        # it has not been updated
        state.initHtml = state.html
        state.initText = state.text

        return state

    componentWillReceiveProps: (nextProps) ->
        if nextProps.message isnt @props.message
            @props.message = nextProps.message
            @setState @getInitialState()


    saveDraft: (event) ->
        event.preventDefault() if event?
        @state.isDraft = true
        @sendActionMessage()

    sendMessage: (event) ->
        event.preventDefault() if event?
        @state.isDraft = false
        @sendActionMessage()

    validateMessage: ->
        return if @state.isDraft
        error =
            'dest': ['to', 'cc', 'bcc']
            'subject': ['subject']
        getGroupedError error, @state

    getMessageFromDOM: ->
        state = _.clone @state
        message = {}

        from = {}
        account = @props.accounts.get @state.accountID
        from.name = name if (name = account.get 'name')
        from.address = address if (address = account.get 'login')
        message.from = [from]

        # TODO : get CC
        # TODO : get BCC
        # TODO : get TO

        _.extend state, message

    sendActionMessage: ->
        if (validate = @validateMessage())
            LayoutActionCreator.alertError t 'compose error no ' + validate[1]
            return

        message = @getMessageFromDOM()
        return unless (changed = hasChanged @state, message)

        @props.isSaving = true
        MessageActionCreator.send message, (error, message) =>
            if error? or not message?
                if @state.isDraft
                    msgKo = t "message action draft ko"
                else
                    msgKo = t "message action sent ko"
                LayoutActionCreator.alertError "#{msgKo} #{error}"
                return

            unless @state.id
                MessageActionCreator.setCurrent message.id

                # Initialize @state
                # Must stay silent (do not use setState)
                _keys = _.without _.keys(message), 'attachments', 'html', 'text'
                _.each _keys, (key) =>
                    if _.isUndefined @state[key]
                        @state[key] = message[key]

                # use another field to prevent the empty conversationID of draft
                # to override the original conversationID
                @state.originalConversationID = @state.conversationID

            # TODO : move this into render
            unless @state.isDraft
                # Display confirmation message
                # for no-draft email
                msgOk = t "message action sent ok"
                LayoutActionCreator.notify msgOk, autoclose: true

                # reload conversation to update its length
                if (cid = message.conversationID)
                    MessageActionCreator.fetchConversation cid

                @finalRedirect()

            @props.isSaving = false

    onDelete: (e) ->
        e.preventDefault()

        subject = @props.message.get 'subject'
        if subject? and subject isnt ''
            params = subject: subject
            confirmMessage = t 'mail confirm delete', params
        else
            confirmMessage = t 'mail confirm delete nosubject'

        doDelete = =>
            LayoutActionCreator.hideModal()
            messageID = @props.message.get('id')

            # this will prevent asking
            # a second time when unmounting component
            @setState isDeleted: true, =>
                MessageActionCreator.delete {messageID}, (error) =>
                    unless error?
                        if @props.callback
                            @props.callback()
                        else
                            # Close Message Box
                            @redirect
                                direction: 'first'
                                action: 'account.mailbox.messages'
                                parameters: [
                                    @props.selectedAccountID
                                    @props.selectedMailboxID
                                ]
                                fullWidth: true

        modal =
            title       : t 'mail confirm delete title'
            subtitle    : confirmMessage
            closeLabel  : t 'mail confirm delete cancel'
            actionLabel : t 'mail confirm delete delete'
            action      : doDelete
        LayoutActionCreator.displayModal modal


    onToggleCc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-cc'
        focus = if not @state.ccShown then 'cc' else ''
        @setState ccShown: not @state.ccShown, focus: focus


    onToggleBcc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-bcc'
        focus = if not @state.bccShown then 'bcc' else ''
        @setState bccShown: not @state.bccShown, focus: focus


    # Get the file picker component (method used to pass it to the editor)
    getPicker: ->
        return @refs.attachments


# set source of attached images
cleanHTML = (html) ->
    parser = new DOMParser()
    doc    = parser.parseFromString html, "text/html"

    if not doc
        doc = document.implementation.createHTMLDocument("")
        doc.documentElement.innerHTML = html

    if doc
        # the contentID of attached images will be in the data-src attribute
        # override image source with this attribute
        imageSrc = (image) ->
            image.setAttribute 'src', "cid:#{image.dataset.src}"
        images = doc.querySelectorAll 'IMG[data-src]'
        imageSrc image for image in images

        return doc.documentElement.innerHTML
    else
        console.error "Unable to parse HTML content of message"
        return html

getGroupedError = (error, message) ->
    type = null
    group = null
    _.find error, (properties, key) ->
        type = _.find properties, (property) ->
            _.isEmpty message[property]
        group = key if type?
        type
    if type or group then [type, group] else null

hasChanged = (obj0, obj1) ->
    result = null
    _.each obj1, (value, key) ->
        unless _.isEqual obj0[key], value
            result = {} unless result
            result[key] = value
    result
