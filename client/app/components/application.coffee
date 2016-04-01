require '../styles/application.styl'

React = require 'react'
{div, section, main, p, span, a, i, strong, form, input, button} = React.DOM

# React components
Menu           = React.createFactory require './menu'
Modal          = React.createFactory require './modal'
ToastContainer = React.createFactory require './toast_container'
Tooltips       = React.createFactory require './tooltips-manager'
MessageList    = React.createFactory require './message-list'
Conversation   = React.createFactory require './conversation'
AccountConfig  = React.createFactory require './account_config'
Compose        = React.createFactory require './compose'

# React Mixins
MessageStore         = require '../stores/message_store'
RouterStore          = require '../stores/router_store'
SettingsStore        = require '../stores/settings_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

ApplicationGetter = require '../getters/application'
RouterGetter = require '../getters/router'

###
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly
###

Application = React.createClass
    displayName: 'Application'

    mixins: [
        TooltipRefesherMixin
        StoreWatchMixin [SettingsStore, RouterStore, MessageStore]
    ]

    getDefaultProps: ->
        ApplicationGetter.getProps 'application'

    getInitialState: ->
        ApplicationGetter.getState()

    componentWillReceiveProps: (nextProps={}) ->
        @setState ApplicationGetter.getState()
        nextProps

    render: ->
        div className: @props.className,

            div className: 'app',
                Menu
                    ref             : 'menu'
                    key             : 'menu-' + @state.accountID
                    accountID       : @state.accountID
                    mailboxID       : @state.mailboxID
                    accounts        : RouterGetter.getAccounts().toArray()
                    composeURL      : RouterGetter.getURL action: 'message.new'
                    newAccountURL   : RouterGetter.getURL action: 'account.new'

                main
                    className: @props.layout

                    if -1 < @state.action.indexOf 'account'
                        accountID = @state.accountID or 'new'
                        tab = RouterGetter.getSelectedTab()
                        AccountConfig
                            key: "account-config-#{accountID}-#{tab}"
                            accountID: @state.accountID

                    else if @state.isEditable
                        Compose
                            ref                  : 'compose-' + @state.action
                            key                  : @state.action + '-' + @state.messageID
                            id                   : @state.messageID
                            action               : @state.action
                            message              : @state.message
                            inReplyTo            : @state.inReplyTo
                            settings             : SettingsStore.get()
                            account              : RouterGetter.getAccounts().get(@state.accountID)

                    else
                        div
                            className: 'panels'
                            MessageList
                                ref         : 'messageList'
                                key         : 'messageList-' + @state.mailboxID
                                accountID   : @state.accountID
                                mailboxID   : @state.mailboxID
                                messageID   : @state.messageID

                            if @state.action is 'message.show'
                                Conversation
                                    ref         : 'conversation'
                                    key         : 'conversation-' + @state.messageID
                                    messageID   : @state.messageID
                                    mailboxID   : @state.mailboxID
                            else
                                section
                                    'key'          : 'placeholder'
                                    'aria-expanded': false

            # Display feedback
            Modal @state.modal if @state.modal?

            ToastContainer()

            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips key: "tooltips"

module.exports = Application
