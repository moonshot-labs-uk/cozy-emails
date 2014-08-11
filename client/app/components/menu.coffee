{div, ul, li, a, span, i} = React.DOM

classer = React.addons.classSet

RouterMixin = require '../mixins/router'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    mixins: [RouterMixin]

    render: ->

        selectedMailboxUrl = @buildUrl
            direction: 'left'
            action: 'mailbox.emails'
            parameter: @props.selectedMailbox.id
            fullWidth: true

        # the button toggles the "compose" screen
        if @props.layout.leftPanel.action is 'compose' or
           @props.layout.rightPanel?.action is 'compose'
            composeUrl = selectedMailboxUrl
        else
            composeUrl = @buildUrl
                direction: 'right'
                action: 'compose'
                parameter: null
                fullWidth: false

        # the button toggle the "new mailbox" screen
        if @props.layout.leftPanel.action is 'mailbox.new'
            newMailboxUrl = selectedMailboxUrl
        else
            newMailboxUrl = @buildUrl
                direction: 'left'
                action: 'mailbox.new'
                fullWidth: true

        classes = classer
            'hidden-xs hidden-sm': not @props.isResponsiveMenuShown
            'col-xs-4 col-md-1': true

        div id: 'menu', className: classes,
            a href: composeUrl, className: 'menu-item compose-action',
                i className: 'fa fa-edit'
                span className: 'mailbox-label', 'Compose'

            ul id: 'mailbox-list', className: 'list-unstyled',
                for mailbox, key in @props.mailboxes
                    @getMailboxRender mailbox, key

            a href: newMailboxUrl, className: 'menu-item new-mailbox-action',
                i className: 'fa fa-inbox'
                span className: 'mailbox-label', 'New mailbox'


    # renders a single mailbox and its submenu
    getMailboxRender: (mailbox, key) ->
        isSelected = (not @props.selectedMailbox and key is 0) \
                    or @props.selectedMailbox.id is mailbox.id

        mailboxClasses = classer active: isSelected
        url = @buildUrl
            direction: 'left'
            action: 'mailbox.emails'
            parameter: mailbox.id
            fullWidth: false

        li className: mailboxClasses, key: key,
            a href: url, className: 'menu-item ' + mailboxClasses,
                i className: 'fa fa-inbox'
                span className: 'badge', mailbox.unreadCount
                span className: 'mailbox-label', mailbox.label

            ul className: 'list-unstyled submenu',
                a href: '#', className: 'menu-item',
                    i className: 'fa fa-star'
                    span className: 'badge', 3
                    span className: 'mailbox-label', 'Favorite'
                a href: '#', className: 'menu-item',
                    i className: 'fa fa-send'
                    span className: 'badge', ''
                    span className: 'mailbox-label', 'Sent'
                a href: '#', className: 'menu-item',
                    i className: 'fa fa-trash-o'
                    span className: 'badge', ''
                    span className: 'mailbox-label', 'Trash'

