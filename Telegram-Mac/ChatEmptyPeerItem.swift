//
//  ChatEmptyPeerItem.swift
//  TelegramMac
//
//  Created by keepcoder on 10/12/2016.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Cocoa
import TGUIKit
import TelegramCore

import Postbox
import SwiftSignalKit

class ChatEmptyPeerItem: TableRowItem {

    private(set) var textViewLayout:TextViewLayout
    
    override var stableId: AnyHashable {
        return 0
    }
    let chatInteraction:ChatInteraction
    
    override var animatable: Bool {
        return false
    }
    
    override var index: Int {
        return -1000
    }
    
    override var height: CGFloat {
        if let table = table {
            return table.frame.height
        }
        return initialSize.height
    }
    
    private let peerViewDisposable = MetaDisposable()
    let presentation: TelegramPresentationTheme
    init(_ initialSize: NSSize, chatInteraction:ChatInteraction, theme: TelegramPresentationTheme) {
        self.chatInteraction = chatInteraction
        self.presentation = theme
        let attr = NSMutableAttributedString()
        var lineSpacing: CGFloat? = 5
        switch chatInteraction.mode {
        case .history, .preview:
            if  chatInteraction.peerId.namespace == Namespaces.Peer.SecretChat {
                _ = attr.append(string: strings().chatSecretChatEmptyHeader, color: theme.chatServiceItemTextColor, font: .medium(.text))
                _ = attr.append(string: "\n")
                _ = attr.append(string: strings().chatSecretChat1Feature, color: theme.chatServiceItemTextColor, font: .medium(.text))
                _ = attr.append(string: "\n")
                _ = attr.append(string: strings().chatSecretChat2Feature, color: theme.chatServiceItemTextColor, font: .medium(.text))
                _ = attr.append(string: "\n")
                _ = attr.append(string: strings().chatSecretChat3Feature, color: theme.chatServiceItemTextColor, font: .medium(.text))
                _ = attr.append(string: "\n")
                _ = attr.append(string: strings().chatSecretChat4Feature, color: theme.chatServiceItemTextColor, font: .medium(.text))
                
            } else if let peer = chatInteraction.peer, peer.isGroup || peer.isSupergroup, peer.groupAccess.isCreator {
                _ = attr.append(string: strings().emptyGroupInfoTitle, color: theme.chatServiceItemTextColor, font: .medium(.text))
                _ = attr.append(string: "\n")
                _ = attr.append(string: strings().emptyGroupInfoSubtitle, color: theme.chatServiceItemTextColor, font: .medium(.text))
                _ = attr.append(string: "\n")
                _ = attr.append(string: strings().emptyGroupInfoLine1(chatInteraction.presentation.limitConfiguration.maxSupergroupMemberCount.formattedWithSeparator), color: theme.chatServiceItemTextColor, font: .medium(.text))
                _ = attr.append(string: "\n")
                _ = attr.append(string: strings().emptyGroupInfoLine2, color: theme.chatServiceItemTextColor, font: .medium(.text))
                _ = attr.append(string: "\n")
                _ = attr.append(string: strings().emptyGroupInfoLine3, color: theme.chatServiceItemTextColor, font: .medium(.text))
                _ = attr.append(string: "\n")
                _ = attr.append(string: strings().emptyGroupInfoLine4, color: theme.chatServiceItemTextColor, font: .medium(.text))
            } else {
                if let restriction = chatInteraction.presentation.restrictionInfo {
                    var hasRule: Bool = false
                    for rule in restriction.rules {
                        #if APP_STORE
                        if rule.platform == "ios" || rule.platform == "all" {
                            if !chatInteraction.context.contentSettings.ignoreContentRestrictionReasons.contains(rule.reason) {
                                _ = attr.append(string: rule.text, color: theme.chatServiceItemTextColor, font: .medium(.text))
                                hasRule = true
                                break
                            }
                        }
                        #endif
                    }
                    if !hasRule {
                        _ = attr.append(string: strings().chatEmptyChat, color: theme.chatServiceItemTextColor, font: .medium(.text))
                        lineSpacing = nil
                    }
                    
                } else {
                    lineSpacing = nil
                    _ = attr.append(string: strings().chatEmptyChat, color: theme.chatServiceItemTextColor, font: .medium(.text))
                }
            }
        case .scheduled:
            lineSpacing = nil
            _ = attr.append(string: strings().chatEmptyChat, color: theme.chatServiceItemTextColor, font: .medium(.text))
        case let .replyThread(_, mode):
            lineSpacing = nil
            switch mode {
            case .comments:
                _ = attr.append(string: strings().chatEmptyComments, color: theme.chatServiceItemTextColor, font: .medium(.text))
            case .replies:
                _ = attr.append(string: strings().chatEmptyReplies, color: theme.chatServiceItemTextColor, font: .medium(.text))
            }
        case .pinned:
            lineSpacing = nil
            _ = attr.append(string: strings().chatEmptyChat, color: theme.chatServiceItemTextColor, font: .medium(.text))
        }
        
        
        textViewLayout = TextViewLayout(attr, alignment: .center, lineSpacing: lineSpacing, alwaysStaticItems: true)
        textViewLayout.interactions = globalLinkExecutor
        
        super.init(initialSize)
        
        
        if chatInteraction.peerId.namespace == Namespaces.Peer.CloudUser {
            peerViewDisposable.set((chatInteraction.context.account.postbox.peerView(id: chatInteraction.peerId) |> deliverOnMainQueue).start(next: { [weak self] peerView in
                if let cachedData = peerView.cachedData as? CachedUserData, let user = peerView.peers[peerView.peerId], let botInfo = cachedData.botInfo {
                    var about = botInfo.description
                    if about.isEmpty {
                        about = cachedData.about ?? strings().chatEmptyChat
                    }
                    if about.isEmpty {
                        about = strings().chatEmptyChat
                    }
                    if user.isScam {
                        about = strings().peerInfoScamWarning
                    }
                    if user.isFake {
                        about = strings().peerInfoFakeWarning
                    }
                    guard let `self` = self else {return}
                    let attr = NSMutableAttributedString()
                    _ = attr.append(string: about, color: theme.chatServiceItemTextColor, font: .medium(.text))
                    attr.detectLinks(type: [.Links, .Mentions, .Hashtags, .Commands], context: chatInteraction.context, color: theme.colors.link, openInfo:chatInteraction.openInfo, hashtag: chatInteraction.context.bindings.globalSearch, command: chatInteraction.sendPlainText, applyProxy: chatInteraction.applyProxy, dotInMention: false)
                    self.textViewLayout = TextViewLayout(attr, alignment: .left)
                    self.textViewLayout.interactions = globalLinkExecutor
                    self.view?.layout()
                }
            }))
        }
        
    }
    
    deinit {
        peerViewDisposable.dispose()
    }
    
    override func viewClass() -> AnyClass {
        return ChatEmptyPeerView.self
    }
    
}


class ChatEmptyPeerView : TableRowView {
    let textView:TextView = TextView()
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(textView)
        //containerView.addSubview(textView)
        textView.isSelectable = false
        textView.userInteractionEnabled = true
        textView.disableBackgroundDrawing = true

    }
    
    override func updateColors() {
        super.updateColors()
        guard let theme = (item as? ChatEmptyPeerItem)?.presentation else {
            return
        }
        if theme.shouldBlurService {
            textView.blurBackground = theme.blurServiceColor
            textView.backgroundColor = backdorColor
        } else {
            textView.backgroundColor = theme.chatServiceItemColor
            textView.blurBackground = nil
        }
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
    }
    
    override var backdorColor: NSColor {
        guard let theme = (item as? ChatEmptyPeerItem)?.presentation else {
            return super.backdorColor
        }
        return theme.backgroundMode.hasWallpaper ? .clear : theme.chatBackground
    }
    
    override func set(item: TableRowItem, animated: Bool) {
        super.set(item: item)
        needsLayout = true
    }
    
    override func layout() {
        super.layout()
        if let item = item as? ChatEmptyPeerItem {
            item.textViewLayout.measure(width: frame.width / 2)
            
            if item.textViewLayout.lineSpacing != nil {
                for (i, line) in item.textViewLayout.lines.enumerated() {
                    if i == 0 {
                        line.penFlush = 0.5
                    } else {
                        line.penFlush = 0.0
                    }
                }
            }
            
            textView.update(item.textViewLayout)
            
            let singleLine = item.textViewLayout.lines.count == 1
            
            textView.setFrameSize( singleLine ? item.textViewLayout.layoutSize.width + 16 : item.textViewLayout.layoutSize.width + 30, singleLine ? 24 : item.textViewLayout.layoutSize.height + 20)
            textView.center()
            
            
            
            textView.layer?.cornerRadius = singleLine ? textView.frame.height / 2 : 8
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

