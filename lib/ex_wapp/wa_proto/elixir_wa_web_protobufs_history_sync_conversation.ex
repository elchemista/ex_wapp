# credo:disable-for-this-file
defmodule WAWebProtobufsHistorySync.Conversation do
  @moduledoc false
  defstruct ID: nil,
            messages: [],
            newJID: nil,
            oldJID: nil,
            lastMsgTimestamp: nil,
            unreadCount: nil,
            readOnly: nil,
            endOfHistoryTransfer: nil,
            ephemeralExpiration: nil,
            ephemeralSettingTimestamp: nil,
            endOfHistoryTransferType: nil,
            conversationTimestamp: nil,
            name: nil,
            pHash: nil,
            notSpam: nil,
            archived: nil,
            disappearingMode: nil,
            unreadMentionCount: nil,
            markedAsUnread: nil,
            participant: [],
            tcToken: nil,
            tcTokenTimestamp: nil,
            contactPrimaryIdentityKey: nil,
            pinned: nil,
            muteEndTime: nil,
            wallpaper: nil,
            mediaVisibility: nil,
            tcTokenSenderTimestamp: nil,
            suspended: nil,
            terminated: nil,
            createdAt: nil,
            createdBy: nil,
            description: nil,
            support: nil,
            isParentGroup: nil,
            isDefaultSubgroup: nil,
            parentGroupID: nil,
            displayName: nil,
            pnJID: nil,
            shareOwnPn: nil,
            pnhDuplicateLidThread: nil,
            lidJID: nil,
            username: nil,
            lidOriginType: nil,
            commentsCount: nil,
            locked: nil,
            systemMessageToInsert: nil,
            capiCreatedGroup: nil,
            accountLid: nil,
            limitSharing: nil,
            limitSharingSettingTimestamp: nil,
            limitSharingTrigger: nil,
            limitSharingInitiatedByMe: nil,
            maibaAiThreadEnabled: nil,
            isMarketingMessageThread: nil,
            isSenderNewAccount: nil,
            afterReadDuration: nil,
            isSenderSuspicious: nil,
            appealStatus: nil,
            appealUpdateTime: nil,
            authAgentParentCompanyName: nil,
            authAgentObaPhoneNumber: nil,
            identityVerification: nil,
            __uf__: []

  (
    (
      @spec encode(struct) :: {:ok, iodata} | {:error, any}
      def encode(msg) do
        try do
          {:ok, encode!(msg)}
        rescue
          e in [Protox.EncodingError, Protox.RequiredFieldsError] -> {:error, e}
        end
      end

      @spec encode!(struct) :: iodata | no_return
      def encode!(msg) do
        []
        |> encode_ID(msg)
        |> encode_messages(msg)
        |> encode_newJID(msg)
        |> encode_oldJID(msg)
        |> encode_lastMsgTimestamp(msg)
        |> encode_unreadCount(msg)
        |> encode_readOnly(msg)
        |> encode_endOfHistoryTransfer(msg)
        |> encode_ephemeralExpiration(msg)
        |> encode_ephemeralSettingTimestamp(msg)
        |> encode_endOfHistoryTransferType(msg)
        |> encode_conversationTimestamp(msg)
        |> encode_name(msg)
        |> encode_pHash(msg)
        |> encode_notSpam(msg)
        |> encode_archived(msg)
        |> encode_disappearingMode(msg)
        |> encode_unreadMentionCount(msg)
        |> encode_markedAsUnread(msg)
        |> encode_participant(msg)
        |> encode_tcToken(msg)
        |> encode_tcTokenTimestamp(msg)
        |> encode_contactPrimaryIdentityKey(msg)
        |> encode_pinned(msg)
        |> encode_muteEndTime(msg)
        |> encode_wallpaper(msg)
        |> encode_mediaVisibility(msg)
        |> encode_tcTokenSenderTimestamp(msg)
        |> encode_suspended(msg)
        |> encode_terminated(msg)
        |> encode_createdAt(msg)
        |> encode_createdBy(msg)
        |> encode_description(msg)
        |> encode_support(msg)
        |> encode_isParentGroup(msg)
        |> encode_isDefaultSubgroup(msg)
        |> encode_parentGroupID(msg)
        |> encode_displayName(msg)
        |> encode_pnJID(msg)
        |> encode_shareOwnPn(msg)
        |> encode_pnhDuplicateLidThread(msg)
        |> encode_lidJID(msg)
        |> encode_username(msg)
        |> encode_lidOriginType(msg)
        |> encode_commentsCount(msg)
        |> encode_locked(msg)
        |> encode_systemMessageToInsert(msg)
        |> encode_capiCreatedGroup(msg)
        |> encode_accountLid(msg)
        |> encode_limitSharing(msg)
        |> encode_limitSharingSettingTimestamp(msg)
        |> encode_limitSharingTrigger(msg)
        |> encode_limitSharingInitiatedByMe(msg)
        |> encode_maibaAiThreadEnabled(msg)
        |> encode_isMarketingMessageThread(msg)
        |> encode_isSenderNewAccount(msg)
        |> encode_afterReadDuration(msg)
        |> encode_isSenderSuspicious(msg)
        |> encode_appealStatus(msg)
        |> encode_appealUpdateTime(msg)
        |> encode_authAgentParentCompanyName(msg)
        |> encode_authAgentObaPhoneNumber(msg)
        |> encode_identityVerification(msg)
        |> encode_unknown_fields(msg)
      end
    )

    []

    [
      defp encode_ID(acc, msg) do
        try do
          case msg."ID" do
            nil -> raise Protox.RequiredFieldsError.new([:ID])
            _ -> [acc, "\n", Protox.Encode.encode_string(msg."ID")]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_messages(acc, msg) do
        try do
          case msg.messages do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\x12", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:messages, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_newJID(acc, msg) do
        try do
          case msg.newJID do
            nil -> acc
            _ -> [acc, "\x1A", Protox.Encode.encode_string(msg.newJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:newJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_oldJID(acc, msg) do
        try do
          case msg.oldJID do
            nil -> acc
            _ -> [acc, "\"", Protox.Encode.encode_string(msg.oldJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:oldJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_lastMsgTimestamp(acc, msg) do
        try do
          case msg.lastMsgTimestamp do
            nil -> acc
            _ -> [acc, "(", Protox.Encode.encode_uint64(msg.lastMsgTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lastMsgTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_unreadCount(acc, msg) do
        try do
          case msg.unreadCount do
            nil -> acc
            _ -> [acc, "0", Protox.Encode.encode_uint32(msg.unreadCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:unreadCount, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_readOnly(acc, msg) do
        try do
          case msg.readOnly do
            nil -> acc
            _ -> [acc, "8", Protox.Encode.encode_bool(msg.readOnly)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:readOnly, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_endOfHistoryTransfer(acc, msg) do
        try do
          case msg.endOfHistoryTransfer do
            nil -> acc
            _ -> [acc, "@", Protox.Encode.encode_bool(msg.endOfHistoryTransfer)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:endOfHistoryTransfer, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralExpiration(acc, msg) do
        try do
          case msg.ephemeralExpiration do
            nil -> acc
            _ -> [acc, "H", Protox.Encode.encode_uint32(msg.ephemeralExpiration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralExpiration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_ephemeralSettingTimestamp(acc, msg) do
        try do
          case msg.ephemeralSettingTimestamp do
            nil -> acc
            _ -> [acc, "P", Protox.Encode.encode_int64(msg.ephemeralSettingTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:ephemeralSettingTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_endOfHistoryTransferType(acc, msg) do
        try do
          case msg.endOfHistoryTransferType do
            nil ->
              acc

            _ ->
              [
                acc,
                "X",
                msg.endOfHistoryTransferType
                |> WAWebProtobufsHistorySync.Conversation.EndOfHistoryTransferType.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:endOfHistoryTransferType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_conversationTimestamp(acc, msg) do
        try do
          case msg.conversationTimestamp do
            nil -> acc
            _ -> [acc, "`", Protox.Encode.encode_uint64(msg.conversationTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:conversationTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_name(acc, msg) do
        try do
          case msg.name do
            nil -> acc
            _ -> [acc, "j", Protox.Encode.encode_string(msg.name)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:name, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pHash(acc, msg) do
        try do
          case msg.pHash do
            nil -> acc
            _ -> [acc, "r", Protox.Encode.encode_string(msg.pHash)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pHash, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_notSpam(acc, msg) do
        try do
          case msg.notSpam do
            nil -> acc
            _ -> [acc, "x", Protox.Encode.encode_bool(msg.notSpam)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:notSpam, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_archived(acc, msg) do
        try do
          case msg.archived do
            nil -> acc
            _ -> [acc, "\x80\x01", Protox.Encode.encode_bool(msg.archived)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:archived, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_disappearingMode(acc, msg) do
        try do
          case msg.disappearingMode do
            nil -> acc
            _ -> [acc, "\x8A\x01", Protox.Encode.encode_message(msg.disappearingMode)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:disappearingMode, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_unreadMentionCount(acc, msg) do
        try do
          case msg.unreadMentionCount do
            nil -> acc
            _ -> [acc, "\x90\x01", Protox.Encode.encode_uint32(msg.unreadMentionCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:unreadMentionCount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_markedAsUnread(acc, msg) do
        try do
          case msg.markedAsUnread do
            nil -> acc
            _ -> [acc, "\x98\x01", Protox.Encode.encode_bool(msg.markedAsUnread)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:markedAsUnread, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_participant(acc, msg) do
        try do
          case msg.participant do
            [] ->
              acc

            values ->
              [
                acc,
                Enum.reduce(values, [], fn value, acc ->
                  [acc, "\xA2\x01", Protox.Encode.encode_message(value)]
                end)
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:participant, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_tcToken(acc, msg) do
        try do
          case msg.tcToken do
            nil -> acc
            _ -> [acc, "\xAA\x01", Protox.Encode.encode_bytes(msg.tcToken)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:tcToken, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_tcTokenTimestamp(acc, msg) do
        try do
          case msg.tcTokenTimestamp do
            nil -> acc
            _ -> [acc, "\xB0\x01", Protox.Encode.encode_uint64(msg.tcTokenTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:tcTokenTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_contactPrimaryIdentityKey(acc, msg) do
        try do
          case msg.contactPrimaryIdentityKey do
            nil -> acc
            _ -> [acc, "\xBA\x01", Protox.Encode.encode_bytes(msg.contactPrimaryIdentityKey)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:contactPrimaryIdentityKey, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_pinned(acc, msg) do
        try do
          case msg.pinned do
            nil -> acc
            _ -> [acc, "\xC0\x01", Protox.Encode.encode_uint32(msg.pinned)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pinned, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_muteEndTime(acc, msg) do
        try do
          case msg.muteEndTime do
            nil -> acc
            _ -> [acc, "\xC8\x01", Protox.Encode.encode_uint64(msg.muteEndTime)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:muteEndTime, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_wallpaper(acc, msg) do
        try do
          case msg.wallpaper do
            nil -> acc
            _ -> [acc, "\xD2\x01", Protox.Encode.encode_message(msg.wallpaper)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:wallpaper, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_mediaVisibility(acc, msg) do
        try do
          case msg.mediaVisibility do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD8\x01",
                msg.mediaVisibility
                |> WAWebProtobufsHistorySync.MediaVisibility.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:mediaVisibility, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_tcTokenSenderTimestamp(acc, msg) do
        try do
          case msg.tcTokenSenderTimestamp do
            nil -> acc
            _ -> [acc, "\xE0\x01", Protox.Encode.encode_uint64(msg.tcTokenSenderTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:tcTokenSenderTimestamp, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_suspended(acc, msg) do
        try do
          case msg.suspended do
            nil -> acc
            _ -> [acc, "\xE8\x01", Protox.Encode.encode_bool(msg.suspended)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:suspended, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_terminated(acc, msg) do
        try do
          case msg.terminated do
            nil -> acc
            _ -> [acc, "\xF0\x01", Protox.Encode.encode_bool(msg.terminated)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:terminated, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_createdAt(acc, msg) do
        try do
          case msg.createdAt do
            nil -> acc
            _ -> [acc, "\xF8\x01", Protox.Encode.encode_uint64(msg.createdAt)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:createdAt, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_createdBy(acc, msg) do
        try do
          case msg.createdBy do
            nil -> acc
            _ -> [acc, "\x82\x02", Protox.Encode.encode_string(msg.createdBy)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:createdBy, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_description(acc, msg) do
        try do
          case msg.description do
            nil -> acc
            _ -> [acc, "\x8A\x02", Protox.Encode.encode_string(msg.description)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:description, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_support(acc, msg) do
        try do
          case msg.support do
            nil -> acc
            _ -> [acc, "\x90\x02", Protox.Encode.encode_bool(msg.support)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:support, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_isParentGroup(acc, msg) do
        try do
          case msg.isParentGroup do
            nil -> acc
            _ -> [acc, "\x98\x02", Protox.Encode.encode_bool(msg.isParentGroup)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isParentGroup, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isDefaultSubgroup(acc, msg) do
        try do
          case msg.isDefaultSubgroup do
            nil -> acc
            _ -> [acc, "\xA0\x02", Protox.Encode.encode_bool(msg.isDefaultSubgroup)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isDefaultSubgroup, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_parentGroupID(acc, msg) do
        try do
          case msg.parentGroupID do
            nil -> acc
            _ -> [acc, "\xAA\x02", Protox.Encode.encode_string(msg.parentGroupID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:parentGroupID, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_displayName(acc, msg) do
        try do
          case msg.displayName do
            nil -> acc
            _ -> [acc, "\xB2\x02", Protox.Encode.encode_string(msg.displayName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:displayName, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pnJID(acc, msg) do
        try do
          case msg.pnJID do
            nil -> acc
            _ -> [acc, "\xBA\x02", Protox.Encode.encode_string(msg.pnJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pnJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_shareOwnPn(acc, msg) do
        try do
          case msg.shareOwnPn do
            nil -> acc
            _ -> [acc, "\xC0\x02", Protox.Encode.encode_bool(msg.shareOwnPn)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:shareOwnPn, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_pnhDuplicateLidThread(acc, msg) do
        try do
          case msg.pnhDuplicateLidThread do
            nil -> acc
            _ -> [acc, "\xC8\x02", Protox.Encode.encode_bool(msg.pnhDuplicateLidThread)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:pnhDuplicateLidThread, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_lidJID(acc, msg) do
        try do
          case msg.lidJID do
            nil -> acc
            _ -> [acc, "\xD2\x02", Protox.Encode.encode_string(msg.lidJID)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lidJID, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_username(acc, msg) do
        try do
          case msg.username do
            nil -> acc
            _ -> [acc, "\xDA\x02", Protox.Encode.encode_string(msg.username)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:username, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_lidOriginType(acc, msg) do
        try do
          case msg.lidOriginType do
            nil -> acc
            _ -> [acc, "\xE2\x02", Protox.Encode.encode_string(msg.lidOriginType)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:lidOriginType, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_commentsCount(acc, msg) do
        try do
          case msg.commentsCount do
            nil -> acc
            _ -> [acc, "\xE8\x02", Protox.Encode.encode_uint32(msg.commentsCount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:commentsCount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_locked(acc, msg) do
        try do
          case msg.locked do
            nil -> acc
            _ -> [acc, "\xF0\x02", Protox.Encode.encode_bool(msg.locked)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:locked, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_systemMessageToInsert(acc, msg) do
        try do
          case msg.systemMessageToInsert do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xF8\x02",
                msg.systemMessageToInsert
                |> WAWebProtobufsHistorySync.PrivacySystemMessage.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:systemMessageToInsert, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_capiCreatedGroup(acc, msg) do
        try do
          case msg.capiCreatedGroup do
            nil -> acc
            _ -> [acc, "\x80\x03", Protox.Encode.encode_bool(msg.capiCreatedGroup)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:capiCreatedGroup, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_accountLid(acc, msg) do
        try do
          case msg.accountLid do
            nil -> acc
            _ -> [acc, "\x8A\x03", Protox.Encode.encode_string(msg.accountLid)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:accountLid, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_limitSharing(acc, msg) do
        try do
          case msg.limitSharing do
            nil -> acc
            _ -> [acc, "\x90\x03", Protox.Encode.encode_bool(msg.limitSharing)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:limitSharing, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_limitSharingSettingTimestamp(acc, msg) do
        try do
          case msg.limitSharingSettingTimestamp do
            nil -> acc
            _ -> [acc, "\x98\x03", Protox.Encode.encode_int64(msg.limitSharingSettingTimestamp)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(
                      :limitSharingSettingTimestamp,
                      "invalid field value"
                    ),
                    __STACKTRACE__
        end
      end,
      defp encode_limitSharingTrigger(acc, msg) do
        try do
          case msg.limitSharingTrigger do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xA0\x03",
                msg.limitSharingTrigger
                |> WACommon.LimitSharing.Trigger.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:limitSharingTrigger, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_limitSharingInitiatedByMe(acc, msg) do
        try do
          case msg.limitSharingInitiatedByMe do
            nil -> acc
            _ -> [acc, "\xA8\x03", Protox.Encode.encode_bool(msg.limitSharingInitiatedByMe)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:limitSharingInitiatedByMe, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_maibaAiThreadEnabled(acc, msg) do
        try do
          case msg.maibaAiThreadEnabled do
            nil -> acc
            _ -> [acc, "\xB0\x03", Protox.Encode.encode_bool(msg.maibaAiThreadEnabled)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:maibaAiThreadEnabled, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isMarketingMessageThread(acc, msg) do
        try do
          case msg.isMarketingMessageThread do
            nil -> acc
            _ -> [acc, "\xB8\x03", Protox.Encode.encode_bool(msg.isMarketingMessageThread)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isMarketingMessageThread, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isSenderNewAccount(acc, msg) do
        try do
          case msg.isSenderNewAccount do
            nil -> acc
            _ -> [acc, "\xC0\x03", Protox.Encode.encode_bool(msg.isSenderNewAccount)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isSenderNewAccount, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_afterReadDuration(acc, msg) do
        try do
          case msg.afterReadDuration do
            nil -> acc
            _ -> [acc, "\xC8\x03", Protox.Encode.encode_uint32(msg.afterReadDuration)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:afterReadDuration, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_isSenderSuspicious(acc, msg) do
        try do
          case msg.isSenderSuspicious do
            nil -> acc
            _ -> [acc, "\xD0\x03", Protox.Encode.encode_bool(msg.isSenderSuspicious)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:isSenderSuspicious, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_appealStatus(acc, msg) do
        try do
          case msg.appealStatus do
            nil ->
              acc

            _ ->
              [
                acc,
                "\xD8\x03",
                msg.appealStatus
                |> WAWebProtobufsHistorySync.Conversation.GroupAppealStatus.encode()
                |> Protox.Encode.encode_enum()
              ]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:appealStatus, "invalid field value"), __STACKTRACE__
        end
      end,
      defp encode_appealUpdateTime(acc, msg) do
        try do
          case msg.appealUpdateTime do
            nil -> acc
            _ -> [acc, "\xE0\x03", Protox.Encode.encode_uint64(msg.appealUpdateTime)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:appealUpdateTime, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_authAgentParentCompanyName(acc, msg) do
        try do
          case msg.authAgentParentCompanyName do
            nil -> acc
            _ -> [acc, "\xEA\x03", Protox.Encode.encode_string(msg.authAgentParentCompanyName)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:authAgentParentCompanyName, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_authAgentObaPhoneNumber(acc, msg) do
        try do
          case msg.authAgentObaPhoneNumber do
            nil -> acc
            _ -> [acc, "\xF2\x03", Protox.Encode.encode_string(msg.authAgentObaPhoneNumber)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:authAgentObaPhoneNumber, "invalid field value"),
                    __STACKTRACE__
        end
      end,
      defp encode_identityVerification(acc, msg) do
        try do
          case msg.identityVerification do
            nil -> acc
            _ -> [acc, "\xFA\x03", Protox.Encode.encode_message(msg.identityVerification)]
          end
        rescue
          ArgumentError ->
            reraise Protox.EncodingError.new(:identityVerification, "invalid field value"),
                    __STACKTRACE__
        end
      end
    ]

    defp encode_unknown_fields(acc, msg) do
      Enum.reduce(msg.__struct__.unknown_fields(msg), acc, fn {tag, wire_type, bytes}, acc ->
        case wire_type do
          0 ->
            [acc, Protox.Encode.make_key_bytes(tag, :int32), bytes]

          1 ->
            [acc, Protox.Encode.make_key_bytes(tag, :double), bytes]

          2 ->
            len_bytes = bytes |> byte_size() |> Protox.Varint.encode()
            [acc, Protox.Encode.make_key_bytes(tag, :packed), len_bytes, bytes]

          5 ->
            [acc, Protox.Encode.make_key_bytes(tag, :float), bytes]
        end
      end)
    end
  )

  (
    (
      @spec decode(binary) :: {:ok, struct} | {:error, any}
      def decode(bytes) do
        try do
          {:ok, decode!(bytes)}
        rescue
          e in [Protox.DecodingError, Protox.IllegalTagError, Protox.RequiredFieldsError] ->
            {:error, e}
        end
      end

      (
        @spec decode!(binary) :: struct | no_return
        def decode!(bytes) do
          {msg, set_fields} =
            parse_key_value([], bytes, struct(WAWebProtobufsHistorySync.Conversation))

          case [:ID] -- set_fields do
            [] -> msg
            missing_fields -> raise Protox.RequiredFieldsError.new(missing_fields)
          end
        end
      )
    )

    (
      @spec parse_key_value([atom], binary, struct) :: {struct, [atom]}
      defp parse_key_value(set_fields, <<>>, msg) do
        {msg, set_fields}
      end

      defp parse_key_value(set_fields, bytes, msg) do
        {new_set_fields, field, rest} =
          case Protox.Decode.parse_key(bytes) do
            {0, _, _} ->
              raise %Protox.IllegalTagError{}

            {1, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:ID | set_fields], [ID: Protox.Decode.validate_string!(delimited)], rest}

            {2, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:messages | set_fields],
               [
                 messages:
                   msg.messages ++ [WAWebProtobufsHistorySync.HistorySyncMsg.decode!(delimited)]
               ], rest}

            {3, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:newJID | set_fields], [newJID: Protox.Decode.validate_string!(delimited)], rest}

            {4, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:oldJID | set_fields], [oldJID: Protox.Decode.validate_string!(delimited)], rest}

            {5, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:lastMsgTimestamp | set_fields], [lastMsgTimestamp: value], rest}

            {6, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:unreadCount | set_fields], [unreadCount: value], rest}

            {7, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:readOnly | set_fields], [readOnly: value], rest}

            {8, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:endOfHistoryTransfer | set_fields], [endOfHistoryTransfer: value], rest}

            {9, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:ephemeralExpiration | set_fields], [ephemeralExpiration: value], rest}

            {10, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)

              {[:ephemeralSettingTimestamp | set_fields], [ephemeralSettingTimestamp: value],
               rest}

            {11, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsHistorySync.Conversation.EndOfHistoryTransferType
                )

              {[:endOfHistoryTransferType | set_fields], [endOfHistoryTransferType: value], rest}

            {12, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:conversationTimestamp | set_fields], [conversationTimestamp: value], rest}

            {13, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:name | set_fields], [name: Protox.Decode.validate_string!(delimited)], rest}

            {14, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:pHash | set_fields], [pHash: Protox.Decode.validate_string!(delimited)], rest}

            {15, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:notSpam | set_fields], [notSpam: value], rest}

            {16, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:archived | set_fields], [archived: value], rest}

            {17, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:disappearingMode | set_fields],
               [
                 disappearingMode:
                   Protox.MergeMessage.merge(
                     msg.disappearingMode,
                     WAWebProtobufsE2E.DisappearingMode.decode!(delimited)
                   )
               ], rest}

            {18, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:unreadMentionCount | set_fields], [unreadMentionCount: value], rest}

            {19, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:markedAsUnread | set_fields], [markedAsUnread: value], rest}

            {20, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:participant | set_fields],
               [
                 participant:
                   msg.participant ++
                     [WAWebProtobufsHistorySync.GroupParticipant.decode!(delimited)]
               ], rest}

            {21, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:tcToken | set_fields], [tcToken: delimited], rest}

            {22, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:tcTokenTimestamp | set_fields], [tcTokenTimestamp: value], rest}

            {23, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:contactPrimaryIdentityKey | set_fields], [contactPrimaryIdentityKey: delimited],
               rest}

            {24, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:pinned | set_fields], [pinned: value], rest}

            {25, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:muteEndTime | set_fields], [muteEndTime: value], rest}

            {26, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:wallpaper | set_fields],
               [
                 wallpaper:
                   Protox.MergeMessage.merge(
                     msg.wallpaper,
                     WAWebProtobufsHistorySync.WallpaperSettings.decode!(delimited)
                   )
               ], rest}

            {27, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsHistorySync.MediaVisibility)

              {[:mediaVisibility | set_fields], [mediaVisibility: value], rest}

            {28, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:tcTokenSenderTimestamp | set_fields], [tcTokenSenderTimestamp: value], rest}

            {29, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:suspended | set_fields], [suspended: value], rest}

            {30, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:terminated | set_fields], [terminated: value], rest}

            {31, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:createdAt | set_fields], [createdAt: value], rest}

            {32, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:createdBy | set_fields], [createdBy: Protox.Decode.validate_string!(delimited)],
               rest}

            {33, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:description | set_fields],
               [description: Protox.Decode.validate_string!(delimited)], rest}

            {34, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:support | set_fields], [support: value], rest}

            {35, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:isParentGroup | set_fields], [isParentGroup: value], rest}

            {36, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:isDefaultSubgroup | set_fields], [isDefaultSubgroup: value], rest}

            {37, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:parentGroupID | set_fields],
               [parentGroupID: Protox.Decode.validate_string!(delimited)], rest}

            {38, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:displayName | set_fields],
               [displayName: Protox.Decode.validate_string!(delimited)], rest}

            {39, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:pnJID | set_fields], [pnJID: Protox.Decode.validate_string!(delimited)], rest}

            {40, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:shareOwnPn | set_fields], [shareOwnPn: value], rest}

            {41, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:pnhDuplicateLidThread | set_fields], [pnhDuplicateLidThread: value], rest}

            {42, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)
              {[:lidJID | set_fields], [lidJID: Protox.Decode.validate_string!(delimited)], rest}

            {43, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:username | set_fields], [username: Protox.Decode.validate_string!(delimited)],
               rest}

            {44, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:lidOriginType | set_fields],
               [lidOriginType: Protox.Decode.validate_string!(delimited)], rest}

            {45, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:commentsCount | set_fields], [commentsCount: value], rest}

            {46, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:locked | set_fields], [locked: value], rest}

            {47, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(bytes, WAWebProtobufsHistorySync.PrivacySystemMessage)

              {[:systemMessageToInsert | set_fields], [systemMessageToInsert: value], rest}

            {48, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:capiCreatedGroup | set_fields], [capiCreatedGroup: value], rest}

            {49, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:accountLid | set_fields],
               [accountLid: Protox.Decode.validate_string!(delimited)], rest}

            {50, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:limitSharing | set_fields], [limitSharing: value], rest}

            {51, _, bytes} ->
              {value, rest} = Protox.Decode.parse_int64(bytes)

              {[:limitSharingSettingTimestamp | set_fields],
               [limitSharingSettingTimestamp: value], rest}

            {52, _, bytes} ->
              {value, rest} = Protox.Decode.parse_enum(bytes, WACommon.LimitSharing.Trigger)
              {[:limitSharingTrigger | set_fields], [limitSharingTrigger: value], rest}

            {53, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)

              {[:limitSharingInitiatedByMe | set_fields], [limitSharingInitiatedByMe: value],
               rest}

            {54, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:maibaAiThreadEnabled | set_fields], [maibaAiThreadEnabled: value], rest}

            {55, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:isMarketingMessageThread | set_fields], [isMarketingMessageThread: value], rest}

            {56, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:isSenderNewAccount | set_fields], [isSenderNewAccount: value], rest}

            {57, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint32(bytes)
              {[:afterReadDuration | set_fields], [afterReadDuration: value], rest}

            {58, _, bytes} ->
              {value, rest} = Protox.Decode.parse_bool(bytes)
              {[:isSenderSuspicious | set_fields], [isSenderSuspicious: value], rest}

            {59, _, bytes} ->
              {value, rest} =
                Protox.Decode.parse_enum(
                  bytes,
                  WAWebProtobufsHistorySync.Conversation.GroupAppealStatus
                )

              {[:appealStatus | set_fields], [appealStatus: value], rest}

            {60, _, bytes} ->
              {value, rest} = Protox.Decode.parse_uint64(bytes)
              {[:appealUpdateTime | set_fields], [appealUpdateTime: value], rest}

            {61, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:authAgentParentCompanyName | set_fields],
               [authAgentParentCompanyName: Protox.Decode.validate_string!(delimited)], rest}

            {62, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:authAgentObaPhoneNumber | set_fields],
               [authAgentObaPhoneNumber: Protox.Decode.validate_string!(delimited)], rest}

            {63, _, bytes} ->
              {len, bytes} = Protox.Varint.decode(bytes)
              {delimited, rest} = Protox.Decode.parse_delimited(bytes, len)

              {[:identityVerification | set_fields],
               [
                 identityVerification:
                   Protox.MergeMessage.merge(
                     msg.identityVerification,
                     WAWebProtobufsHistorySync.IdentityVerificationState.decode!(delimited)
                   )
               ], rest}

            {tag, wire_type, rest} ->
              {value, rest} = Protox.Decode.parse_unknown(tag, wire_type, rest)

              {set_fields,
               [
                 {msg.__struct__.unknown_fields_name(),
                  [value | msg.__struct__.unknown_fields(msg)]}
               ], rest}
          end

        msg_updated = struct(msg, field)
        parse_key_value(new_set_fields, rest, msg_updated)
      end
    )

    []
  )

  (
    @spec json_decode(iodata(), keyword()) :: {:ok, struct()} | {:error, any()}
    def json_decode(input, opts \\ []) do
      try do
        {:ok, json_decode!(input, opts)}
      rescue
        e in Protox.JsonDecodingError -> {:error, e}
      end
    end

    @spec json_decode!(iodata(), keyword()) :: struct() | no_return()
    def json_decode!(input, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :decode)

      Protox.JsonDecode.decode!(
        input,
        WAWebProtobufsHistorySync.Conversation,
        &json_library_wrapper.decode!(json_library, &1)
      )
    end

    @spec json_encode(struct(), keyword()) :: {:ok, iodata()} | {:error, any()}
    def json_encode(msg, opts \\ []) do
      try do
        {:ok, json_encode!(msg, opts)}
      rescue
        e in Protox.JsonEncodingError -> {:error, e}
      end
    end

    @spec json_encode!(struct(), keyword()) :: iodata() | no_return()
    def json_encode!(msg, opts \\ []) do
      {json_library_wrapper, json_library} = Protox.JsonLibrary.get_library(opts, :encode)
      Protox.JsonEncode.encode!(msg, &json_library_wrapper.encode!(json_library, &1))
    end
  )

  (
    @deprecated "Use fields_defs()/0 instead"
    @spec defs() :: %{
            required(non_neg_integer) => {atom, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs() do
      %{
        1 => {:ID, {:scalar, ""}, :string},
        2 => {:messages, :unpacked, {:message, WAWebProtobufsHistorySync.HistorySyncMsg}},
        3 => {:newJID, {:scalar, ""}, :string},
        4 => {:oldJID, {:scalar, ""}, :string},
        5 => {:lastMsgTimestamp, {:scalar, 0}, :uint64},
        6 => {:unreadCount, {:scalar, 0}, :uint32},
        7 => {:readOnly, {:scalar, false}, :bool},
        8 => {:endOfHistoryTransfer, {:scalar, false}, :bool},
        9 => {:ephemeralExpiration, {:scalar, 0}, :uint32},
        10 => {:ephemeralSettingTimestamp, {:scalar, 0}, :int64},
        11 =>
          {:endOfHistoryTransferType, {:scalar, :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY},
           {:enum, WAWebProtobufsHistorySync.Conversation.EndOfHistoryTransferType}},
        12 => {:conversationTimestamp, {:scalar, 0}, :uint64},
        13 => {:name, {:scalar, ""}, :string},
        14 => {:pHash, {:scalar, ""}, :string},
        15 => {:notSpam, {:scalar, false}, :bool},
        16 => {:archived, {:scalar, false}, :bool},
        17 => {:disappearingMode, {:scalar, nil}, {:message, WAWebProtobufsE2E.DisappearingMode}},
        18 => {:unreadMentionCount, {:scalar, 0}, :uint32},
        19 => {:markedAsUnread, {:scalar, false}, :bool},
        20 => {:participant, :unpacked, {:message, WAWebProtobufsHistorySync.GroupParticipant}},
        21 => {:tcToken, {:scalar, ""}, :bytes},
        22 => {:tcTokenTimestamp, {:scalar, 0}, :uint64},
        23 => {:contactPrimaryIdentityKey, {:scalar, ""}, :bytes},
        24 => {:pinned, {:scalar, 0}, :uint32},
        25 => {:muteEndTime, {:scalar, 0}, :uint64},
        26 =>
          {:wallpaper, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.WallpaperSettings}},
        27 =>
          {:mediaVisibility, {:scalar, :DEFAULT},
           {:enum, WAWebProtobufsHistorySync.MediaVisibility}},
        28 => {:tcTokenSenderTimestamp, {:scalar, 0}, :uint64},
        29 => {:suspended, {:scalar, false}, :bool},
        30 => {:terminated, {:scalar, false}, :bool},
        31 => {:createdAt, {:scalar, 0}, :uint64},
        32 => {:createdBy, {:scalar, ""}, :string},
        33 => {:description, {:scalar, ""}, :string},
        34 => {:support, {:scalar, false}, :bool},
        35 => {:isParentGroup, {:scalar, false}, :bool},
        36 => {:isDefaultSubgroup, {:scalar, false}, :bool},
        37 => {:parentGroupID, {:scalar, ""}, :string},
        38 => {:displayName, {:scalar, ""}, :string},
        39 => {:pnJID, {:scalar, ""}, :string},
        40 => {:shareOwnPn, {:scalar, false}, :bool},
        41 => {:pnhDuplicateLidThread, {:scalar, false}, :bool},
        42 => {:lidJID, {:scalar, ""}, :string},
        43 => {:username, {:scalar, ""}, :string},
        44 => {:lidOriginType, {:scalar, ""}, :string},
        45 => {:commentsCount, {:scalar, 0}, :uint32},
        46 => {:locked, {:scalar, false}, :bool},
        47 =>
          {:systemMessageToInsert, {:scalar, :E2EE_MSG},
           {:enum, WAWebProtobufsHistorySync.PrivacySystemMessage}},
        48 => {:capiCreatedGroup, {:scalar, false}, :bool},
        49 => {:accountLid, {:scalar, ""}, :string},
        50 => {:limitSharing, {:scalar, false}, :bool},
        51 => {:limitSharingSettingTimestamp, {:scalar, 0}, :int64},
        52 => {:limitSharingTrigger, {:scalar, :UNKNOWN}, {:enum, WACommon.LimitSharing.Trigger}},
        53 => {:limitSharingInitiatedByMe, {:scalar, false}, :bool},
        54 => {:maibaAiThreadEnabled, {:scalar, false}, :bool},
        55 => {:isMarketingMessageThread, {:scalar, false}, :bool},
        56 => {:isSenderNewAccount, {:scalar, false}, :bool},
        57 => {:afterReadDuration, {:scalar, 0}, :uint32},
        58 => {:isSenderSuspicious, {:scalar, false}, :bool},
        59 =>
          {:appealStatus, {:scalar, :NO_APPEAL},
           {:enum, WAWebProtobufsHistorySync.Conversation.GroupAppealStatus}},
        60 => {:appealUpdateTime, {:scalar, 0}, :uint64},
        61 => {:authAgentParentCompanyName, {:scalar, ""}, :string},
        62 => {:authAgentObaPhoneNumber, {:scalar, ""}, :string},
        63 =>
          {:identityVerification, {:scalar, nil},
           {:message, WAWebProtobufsHistorySync.IdentityVerificationState}}
      }
    end

    @deprecated "Use fields_defs()/0 instead"
    @spec defs_by_name() :: %{
            required(atom) => {non_neg_integer, Protox.Types.kind(), Protox.Types.type()}
          }
    def defs_by_name() do
      %{
        ID: {1, {:scalar, ""}, :string},
        accountLid: {49, {:scalar, ""}, :string},
        afterReadDuration: {57, {:scalar, 0}, :uint32},
        appealStatus:
          {59, {:scalar, :NO_APPEAL},
           {:enum, WAWebProtobufsHistorySync.Conversation.GroupAppealStatus}},
        appealUpdateTime: {60, {:scalar, 0}, :uint64},
        archived: {16, {:scalar, false}, :bool},
        authAgentObaPhoneNumber: {62, {:scalar, ""}, :string},
        authAgentParentCompanyName: {61, {:scalar, ""}, :string},
        capiCreatedGroup: {48, {:scalar, false}, :bool},
        commentsCount: {45, {:scalar, 0}, :uint32},
        contactPrimaryIdentityKey: {23, {:scalar, ""}, :bytes},
        conversationTimestamp: {12, {:scalar, 0}, :uint64},
        createdAt: {31, {:scalar, 0}, :uint64},
        createdBy: {32, {:scalar, ""}, :string},
        description: {33, {:scalar, ""}, :string},
        disappearingMode: {17, {:scalar, nil}, {:message, WAWebProtobufsE2E.DisappearingMode}},
        displayName: {38, {:scalar, ""}, :string},
        endOfHistoryTransfer: {8, {:scalar, false}, :bool},
        endOfHistoryTransferType:
          {11, {:scalar, :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY},
           {:enum, WAWebProtobufsHistorySync.Conversation.EndOfHistoryTransferType}},
        ephemeralExpiration: {9, {:scalar, 0}, :uint32},
        ephemeralSettingTimestamp: {10, {:scalar, 0}, :int64},
        identityVerification:
          {63, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.IdentityVerificationState}},
        isDefaultSubgroup: {36, {:scalar, false}, :bool},
        isMarketingMessageThread: {55, {:scalar, false}, :bool},
        isParentGroup: {35, {:scalar, false}, :bool},
        isSenderNewAccount: {56, {:scalar, false}, :bool},
        isSenderSuspicious: {58, {:scalar, false}, :bool},
        lastMsgTimestamp: {5, {:scalar, 0}, :uint64},
        lidJID: {42, {:scalar, ""}, :string},
        lidOriginType: {44, {:scalar, ""}, :string},
        limitSharing: {50, {:scalar, false}, :bool},
        limitSharingInitiatedByMe: {53, {:scalar, false}, :bool},
        limitSharingSettingTimestamp: {51, {:scalar, 0}, :int64},
        limitSharingTrigger: {52, {:scalar, :UNKNOWN}, {:enum, WACommon.LimitSharing.Trigger}},
        locked: {46, {:scalar, false}, :bool},
        maibaAiThreadEnabled: {54, {:scalar, false}, :bool},
        markedAsUnread: {19, {:scalar, false}, :bool},
        mediaVisibility:
          {27, {:scalar, :DEFAULT}, {:enum, WAWebProtobufsHistorySync.MediaVisibility}},
        messages: {2, :unpacked, {:message, WAWebProtobufsHistorySync.HistorySyncMsg}},
        muteEndTime: {25, {:scalar, 0}, :uint64},
        name: {13, {:scalar, ""}, :string},
        newJID: {3, {:scalar, ""}, :string},
        notSpam: {15, {:scalar, false}, :bool},
        oldJID: {4, {:scalar, ""}, :string},
        pHash: {14, {:scalar, ""}, :string},
        parentGroupID: {37, {:scalar, ""}, :string},
        participant: {20, :unpacked, {:message, WAWebProtobufsHistorySync.GroupParticipant}},
        pinned: {24, {:scalar, 0}, :uint32},
        pnJID: {39, {:scalar, ""}, :string},
        pnhDuplicateLidThread: {41, {:scalar, false}, :bool},
        readOnly: {7, {:scalar, false}, :bool},
        shareOwnPn: {40, {:scalar, false}, :bool},
        support: {34, {:scalar, false}, :bool},
        suspended: {29, {:scalar, false}, :bool},
        systemMessageToInsert:
          {47, {:scalar, :E2EE_MSG}, {:enum, WAWebProtobufsHistorySync.PrivacySystemMessage}},
        tcToken: {21, {:scalar, ""}, :bytes},
        tcTokenSenderTimestamp: {28, {:scalar, 0}, :uint64},
        tcTokenTimestamp: {22, {:scalar, 0}, :uint64},
        terminated: {30, {:scalar, false}, :bool},
        unreadCount: {6, {:scalar, 0}, :uint32},
        unreadMentionCount: {18, {:scalar, 0}, :uint32},
        username: {43, {:scalar, ""}, :string},
        wallpaper: {26, {:scalar, nil}, {:message, WAWebProtobufsHistorySync.WallpaperSettings}}
      }
    end
  )

  (
    @spec fields_defs() :: list(Protox.Field.t())
    def fields_defs() do
      [
        %{
          __struct__: Protox.Field,
          json_name: "ID",
          kind: {:scalar, ""},
          label: :required,
          name: :ID,
          tag: 1,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "messages",
          kind: :unpacked,
          label: :repeated,
          name: :messages,
          tag: 2,
          type: {:message, WAWebProtobufsHistorySync.HistorySyncMsg}
        },
        %{
          __struct__: Protox.Field,
          json_name: "newJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :newJID,
          tag: 3,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "oldJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :oldJID,
          tag: 4,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "lastMsgTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :lastMsgTimestamp,
          tag: 5,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "unreadCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :unreadCount,
          tag: 6,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "readOnly",
          kind: {:scalar, false},
          label: :optional,
          name: :readOnly,
          tag: 7,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "endOfHistoryTransfer",
          kind: {:scalar, false},
          label: :optional,
          name: :endOfHistoryTransfer,
          tag: 8,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralExpiration",
          kind: {:scalar, 0},
          label: :optional,
          name: :ephemeralExpiration,
          tag: 9,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "ephemeralSettingTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :ephemeralSettingTimestamp,
          tag: 10,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "endOfHistoryTransferType",
          kind: {:scalar, :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY},
          label: :optional,
          name: :endOfHistoryTransferType,
          tag: 11,
          type: {:enum, WAWebProtobufsHistorySync.Conversation.EndOfHistoryTransferType}
        },
        %{
          __struct__: Protox.Field,
          json_name: "conversationTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :conversationTimestamp,
          tag: 12,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "name",
          kind: {:scalar, ""},
          label: :optional,
          name: :name,
          tag: 13,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "pHash",
          kind: {:scalar, ""},
          label: :optional,
          name: :pHash,
          tag: 14,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "notSpam",
          kind: {:scalar, false},
          label: :optional,
          name: :notSpam,
          tag: 15,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "archived",
          kind: {:scalar, false},
          label: :optional,
          name: :archived,
          tag: 16,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "disappearingMode",
          kind: {:scalar, nil},
          label: :optional,
          name: :disappearingMode,
          tag: 17,
          type: {:message, WAWebProtobufsE2E.DisappearingMode}
        },
        %{
          __struct__: Protox.Field,
          json_name: "unreadMentionCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :unreadMentionCount,
          tag: 18,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "markedAsUnread",
          kind: {:scalar, false},
          label: :optional,
          name: :markedAsUnread,
          tag: 19,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "participant",
          kind: :unpacked,
          label: :repeated,
          name: :participant,
          tag: 20,
          type: {:message, WAWebProtobufsHistorySync.GroupParticipant}
        },
        %{
          __struct__: Protox.Field,
          json_name: "tcToken",
          kind: {:scalar, ""},
          label: :optional,
          name: :tcToken,
          tag: 21,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "tcTokenTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :tcTokenTimestamp,
          tag: 22,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "contactPrimaryIdentityKey",
          kind: {:scalar, ""},
          label: :optional,
          name: :contactPrimaryIdentityKey,
          tag: 23,
          type: :bytes
        },
        %{
          __struct__: Protox.Field,
          json_name: "pinned",
          kind: {:scalar, 0},
          label: :optional,
          name: :pinned,
          tag: 24,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "muteEndTime",
          kind: {:scalar, 0},
          label: :optional,
          name: :muteEndTime,
          tag: 25,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "wallpaper",
          kind: {:scalar, nil},
          label: :optional,
          name: :wallpaper,
          tag: 26,
          type: {:message, WAWebProtobufsHistorySync.WallpaperSettings}
        },
        %{
          __struct__: Protox.Field,
          json_name: "mediaVisibility",
          kind: {:scalar, :DEFAULT},
          label: :optional,
          name: :mediaVisibility,
          tag: 27,
          type: {:enum, WAWebProtobufsHistorySync.MediaVisibility}
        },
        %{
          __struct__: Protox.Field,
          json_name: "tcTokenSenderTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :tcTokenSenderTimestamp,
          tag: 28,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "suspended",
          kind: {:scalar, false},
          label: :optional,
          name: :suspended,
          tag: 29,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "terminated",
          kind: {:scalar, false},
          label: :optional,
          name: :terminated,
          tag: 30,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "createdAt",
          kind: {:scalar, 0},
          label: :optional,
          name: :createdAt,
          tag: 31,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "createdBy",
          kind: {:scalar, ""},
          label: :optional,
          name: :createdBy,
          tag: 32,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "description",
          kind: {:scalar, ""},
          label: :optional,
          name: :description,
          tag: 33,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "support",
          kind: {:scalar, false},
          label: :optional,
          name: :support,
          tag: 34,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isParentGroup",
          kind: {:scalar, false},
          label: :optional,
          name: :isParentGroup,
          tag: 35,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isDefaultSubgroup",
          kind: {:scalar, false},
          label: :optional,
          name: :isDefaultSubgroup,
          tag: 36,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "parentGroupID",
          kind: {:scalar, ""},
          label: :optional,
          name: :parentGroupID,
          tag: 37,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "displayName",
          kind: {:scalar, ""},
          label: :optional,
          name: :displayName,
          tag: 38,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "pnJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :pnJID,
          tag: 39,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "shareOwnPn",
          kind: {:scalar, false},
          label: :optional,
          name: :shareOwnPn,
          tag: 40,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "pnhDuplicateLidThread",
          kind: {:scalar, false},
          label: :optional,
          name: :pnhDuplicateLidThread,
          tag: 41,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "lidJID",
          kind: {:scalar, ""},
          label: :optional,
          name: :lidJID,
          tag: 42,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "username",
          kind: {:scalar, ""},
          label: :optional,
          name: :username,
          tag: 43,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "lidOriginType",
          kind: {:scalar, ""},
          label: :optional,
          name: :lidOriginType,
          tag: 44,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "commentsCount",
          kind: {:scalar, 0},
          label: :optional,
          name: :commentsCount,
          tag: 45,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "locked",
          kind: {:scalar, false},
          label: :optional,
          name: :locked,
          tag: 46,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "systemMessageToInsert",
          kind: {:scalar, :E2EE_MSG},
          label: :optional,
          name: :systemMessageToInsert,
          tag: 47,
          type: {:enum, WAWebProtobufsHistorySync.PrivacySystemMessage}
        },
        %{
          __struct__: Protox.Field,
          json_name: "capiCreatedGroup",
          kind: {:scalar, false},
          label: :optional,
          name: :capiCreatedGroup,
          tag: 48,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "accountLid",
          kind: {:scalar, ""},
          label: :optional,
          name: :accountLid,
          tag: 49,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "limitSharing",
          kind: {:scalar, false},
          label: :optional,
          name: :limitSharing,
          tag: 50,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "limitSharingSettingTimestamp",
          kind: {:scalar, 0},
          label: :optional,
          name: :limitSharingSettingTimestamp,
          tag: 51,
          type: :int64
        },
        %{
          __struct__: Protox.Field,
          json_name: "limitSharingTrigger",
          kind: {:scalar, :UNKNOWN},
          label: :optional,
          name: :limitSharingTrigger,
          tag: 52,
          type: {:enum, WACommon.LimitSharing.Trigger}
        },
        %{
          __struct__: Protox.Field,
          json_name: "limitSharingInitiatedByMe",
          kind: {:scalar, false},
          label: :optional,
          name: :limitSharingInitiatedByMe,
          tag: 53,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "maibaAiThreadEnabled",
          kind: {:scalar, false},
          label: :optional,
          name: :maibaAiThreadEnabled,
          tag: 54,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isMarketingMessageThread",
          kind: {:scalar, false},
          label: :optional,
          name: :isMarketingMessageThread,
          tag: 55,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "isSenderNewAccount",
          kind: {:scalar, false},
          label: :optional,
          name: :isSenderNewAccount,
          tag: 56,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "afterReadDuration",
          kind: {:scalar, 0},
          label: :optional,
          name: :afterReadDuration,
          tag: 57,
          type: :uint32
        },
        %{
          __struct__: Protox.Field,
          json_name: "isSenderSuspicious",
          kind: {:scalar, false},
          label: :optional,
          name: :isSenderSuspicious,
          tag: 58,
          type: :bool
        },
        %{
          __struct__: Protox.Field,
          json_name: "appealStatus",
          kind: {:scalar, :NO_APPEAL},
          label: :optional,
          name: :appealStatus,
          tag: 59,
          type: {:enum, WAWebProtobufsHistorySync.Conversation.GroupAppealStatus}
        },
        %{
          __struct__: Protox.Field,
          json_name: "appealUpdateTime",
          kind: {:scalar, 0},
          label: :optional,
          name: :appealUpdateTime,
          tag: 60,
          type: :uint64
        },
        %{
          __struct__: Protox.Field,
          json_name: "authAgentParentCompanyName",
          kind: {:scalar, ""},
          label: :optional,
          name: :authAgentParentCompanyName,
          tag: 61,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "authAgentObaPhoneNumber",
          kind: {:scalar, ""},
          label: :optional,
          name: :authAgentObaPhoneNumber,
          tag: 62,
          type: :string
        },
        %{
          __struct__: Protox.Field,
          json_name: "identityVerification",
          kind: {:scalar, nil},
          label: :optional,
          name: :identityVerification,
          tag: 63,
          type: {:message, WAWebProtobufsHistorySync.IdentityVerificationState}
        }
      ]
    end

    [
      @spec(field_def(atom) :: {:ok, Protox.Field.t()} | {:error, :no_such_field}),
      (
        def field_def(:ID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ID",
             kind: {:scalar, ""},
             label: :required,
             name: :ID,
             tag: 1,
             type: :string
           }}
        end

        def field_def("ID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ID",
             kind: {:scalar, ""},
             label: :required,
             name: :ID,
             tag: 1,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:messages) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messages",
             kind: :unpacked,
             label: :repeated,
             name: :messages,
             tag: 2,
             type: {:message, WAWebProtobufsHistorySync.HistorySyncMsg}
           }}
        end

        def field_def("messages") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "messages",
             kind: :unpacked,
             label: :repeated,
             name: :messages,
             tag: 2,
             type: {:message, WAWebProtobufsHistorySync.HistorySyncMsg}
           }}
        end

        []
      ),
      (
        def field_def(:newJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :newJID,
             tag: 3,
             type: :string
           }}
        end

        def field_def("newJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "newJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :newJID,
             tag: 3,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:oldJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :oldJID,
             tag: 4,
             type: :string
           }}
        end

        def field_def("oldJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "oldJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :oldJID,
             tag: 4,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:lastMsgTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lastMsgTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :lastMsgTimestamp,
             tag: 5,
             type: :uint64
           }}
        end

        def field_def("lastMsgTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lastMsgTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :lastMsgTimestamp,
             tag: 5,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:unreadCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unreadCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :unreadCount,
             tag: 6,
             type: :uint32
           }}
        end

        def field_def("unreadCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unreadCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :unreadCount,
             tag: 6,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:readOnly) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "readOnly",
             kind: {:scalar, false},
             label: :optional,
             name: :readOnly,
             tag: 7,
             type: :bool
           }}
        end

        def field_def("readOnly") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "readOnly",
             kind: {:scalar, false},
             label: :optional,
             name: :readOnly,
             tag: 7,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:endOfHistoryTransfer) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endOfHistoryTransfer",
             kind: {:scalar, false},
             label: :optional,
             name: :endOfHistoryTransfer,
             tag: 8,
             type: :bool
           }}
        end

        def field_def("endOfHistoryTransfer") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endOfHistoryTransfer",
             kind: {:scalar, false},
             label: :optional,
             name: :endOfHistoryTransfer,
             tag: 8,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralExpiration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralExpiration",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralExpiration,
             tag: 9,
             type: :uint32
           }}
        end

        def field_def("ephemeralExpiration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralExpiration",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralExpiration,
             tag: 9,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:ephemeralSettingTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralSettingTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralSettingTimestamp,
             tag: 10,
             type: :int64
           }}
        end

        def field_def("ephemeralSettingTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "ephemeralSettingTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :ephemeralSettingTimestamp,
             tag: 10,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:endOfHistoryTransferType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endOfHistoryTransferType",
             kind: {:scalar, :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY},
             label: :optional,
             name: :endOfHistoryTransferType,
             tag: 11,
             type: {:enum, WAWebProtobufsHistorySync.Conversation.EndOfHistoryTransferType}
           }}
        end

        def field_def("endOfHistoryTransferType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "endOfHistoryTransferType",
             kind: {:scalar, :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY},
             label: :optional,
             name: :endOfHistoryTransferType,
             tag: 11,
             type: {:enum, WAWebProtobufsHistorySync.Conversation.EndOfHistoryTransferType}
           }}
        end

        []
      ),
      (
        def field_def(:conversationTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversationTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :conversationTimestamp,
             tag: 12,
             type: :uint64
           }}
        end

        def field_def("conversationTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "conversationTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :conversationTimestamp,
             tag: 12,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:name) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
             tag: 13,
             type: :string
           }}
        end

        def field_def("name") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "name",
             kind: {:scalar, ""},
             label: :optional,
             name: :name,
             tag: 13,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:pHash) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :pHash,
             tag: 14,
             type: :string
           }}
        end

        def field_def("pHash") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pHash",
             kind: {:scalar, ""},
             label: :optional,
             name: :pHash,
             tag: 14,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:notSpam) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notSpam",
             kind: {:scalar, false},
             label: :optional,
             name: :notSpam,
             tag: 15,
             type: :bool
           }}
        end

        def field_def("notSpam") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "notSpam",
             kind: {:scalar, false},
             label: :optional,
             name: :notSpam,
             tag: 15,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:archived) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "archived",
             kind: {:scalar, false},
             label: :optional,
             name: :archived,
             tag: 16,
             type: :bool
           }}
        end

        def field_def("archived") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "archived",
             kind: {:scalar, false},
             label: :optional,
             name: :archived,
             tag: 16,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:disappearingMode) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disappearingMode",
             kind: {:scalar, nil},
             label: :optional,
             name: :disappearingMode,
             tag: 17,
             type: {:message, WAWebProtobufsE2E.DisappearingMode}
           }}
        end

        def field_def("disappearingMode") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "disappearingMode",
             kind: {:scalar, nil},
             label: :optional,
             name: :disappearingMode,
             tag: 17,
             type: {:message, WAWebProtobufsE2E.DisappearingMode}
           }}
        end

        []
      ),
      (
        def field_def(:unreadMentionCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unreadMentionCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :unreadMentionCount,
             tag: 18,
             type: :uint32
           }}
        end

        def field_def("unreadMentionCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "unreadMentionCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :unreadMentionCount,
             tag: 18,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:markedAsUnread) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "markedAsUnread",
             kind: {:scalar, false},
             label: :optional,
             name: :markedAsUnread,
             tag: 19,
             type: :bool
           }}
        end

        def field_def("markedAsUnread") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "markedAsUnread",
             kind: {:scalar, false},
             label: :optional,
             name: :markedAsUnread,
             tag: 19,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:participant) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "participant",
             kind: :unpacked,
             label: :repeated,
             name: :participant,
             tag: 20,
             type: {:message, WAWebProtobufsHistorySync.GroupParticipant}
           }}
        end

        def field_def("participant") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "participant",
             kind: :unpacked,
             label: :repeated,
             name: :participant,
             tag: 20,
             type: {:message, WAWebProtobufsHistorySync.GroupParticipant}
           }}
        end

        []
      ),
      (
        def field_def(:tcToken) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tcToken",
             kind: {:scalar, ""},
             label: :optional,
             name: :tcToken,
             tag: 21,
             type: :bytes
           }}
        end

        def field_def("tcToken") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tcToken",
             kind: {:scalar, ""},
             label: :optional,
             name: :tcToken,
             tag: 21,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:tcTokenTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tcTokenTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :tcTokenTimestamp,
             tag: 22,
             type: :uint64
           }}
        end

        def field_def("tcTokenTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tcTokenTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :tcTokenTimestamp,
             tag: 22,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:contactPrimaryIdentityKey) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactPrimaryIdentityKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :contactPrimaryIdentityKey,
             tag: 23,
             type: :bytes
           }}
        end

        def field_def("contactPrimaryIdentityKey") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "contactPrimaryIdentityKey",
             kind: {:scalar, ""},
             label: :optional,
             name: :contactPrimaryIdentityKey,
             tag: 23,
             type: :bytes
           }}
        end

        []
      ),
      (
        def field_def(:pinned) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pinned",
             kind: {:scalar, 0},
             label: :optional,
             name: :pinned,
             tag: 24,
             type: :uint32
           }}
        end

        def field_def("pinned") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pinned",
             kind: {:scalar, 0},
             label: :optional,
             name: :pinned,
             tag: 24,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:muteEndTime) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "muteEndTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :muteEndTime,
             tag: 25,
             type: :uint64
           }}
        end

        def field_def("muteEndTime") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "muteEndTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :muteEndTime,
             tag: 25,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:wallpaper) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wallpaper",
             kind: {:scalar, nil},
             label: :optional,
             name: :wallpaper,
             tag: 26,
             type: {:message, WAWebProtobufsHistorySync.WallpaperSettings}
           }}
        end

        def field_def("wallpaper") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "wallpaper",
             kind: {:scalar, nil},
             label: :optional,
             name: :wallpaper,
             tag: 26,
             type: {:message, WAWebProtobufsHistorySync.WallpaperSettings}
           }}
        end

        []
      ),
      (
        def field_def(:mediaVisibility) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaVisibility",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :mediaVisibility,
             tag: 27,
             type: {:enum, WAWebProtobufsHistorySync.MediaVisibility}
           }}
        end

        def field_def("mediaVisibility") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "mediaVisibility",
             kind: {:scalar, :DEFAULT},
             label: :optional,
             name: :mediaVisibility,
             tag: 27,
             type: {:enum, WAWebProtobufsHistorySync.MediaVisibility}
           }}
        end

        []
      ),
      (
        def field_def(:tcTokenSenderTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tcTokenSenderTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :tcTokenSenderTimestamp,
             tag: 28,
             type: :uint64
           }}
        end

        def field_def("tcTokenSenderTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "tcTokenSenderTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :tcTokenSenderTimestamp,
             tag: 28,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:suspended) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "suspended",
             kind: {:scalar, false},
             label: :optional,
             name: :suspended,
             tag: 29,
             type: :bool
           }}
        end

        def field_def("suspended") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "suspended",
             kind: {:scalar, false},
             label: :optional,
             name: :suspended,
             tag: 29,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:terminated) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "terminated",
             kind: {:scalar, false},
             label: :optional,
             name: :terminated,
             tag: 30,
             type: :bool
           }}
        end

        def field_def("terminated") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "terminated",
             kind: {:scalar, false},
             label: :optional,
             name: :terminated,
             tag: 30,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:createdAt) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createdAt",
             kind: {:scalar, 0},
             label: :optional,
             name: :createdAt,
             tag: 31,
             type: :uint64
           }}
        end

        def field_def("createdAt") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createdAt",
             kind: {:scalar, 0},
             label: :optional,
             name: :createdAt,
             tag: 31,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:createdBy) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createdBy",
             kind: {:scalar, ""},
             label: :optional,
             name: :createdBy,
             tag: 32,
             type: :string
           }}
        end

        def field_def("createdBy") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "createdBy",
             kind: {:scalar, ""},
             label: :optional,
             name: :createdBy,
             tag: 32,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:description) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "description",
             kind: {:scalar, ""},
             label: :optional,
             name: :description,
             tag: 33,
             type: :string
           }}
        end

        def field_def("description") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "description",
             kind: {:scalar, ""},
             label: :optional,
             name: :description,
             tag: 33,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:support) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "support",
             kind: {:scalar, false},
             label: :optional,
             name: :support,
             tag: 34,
             type: :bool
           }}
        end

        def field_def("support") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "support",
             kind: {:scalar, false},
             label: :optional,
             name: :support,
             tag: 34,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isParentGroup) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isParentGroup",
             kind: {:scalar, false},
             label: :optional,
             name: :isParentGroup,
             tag: 35,
             type: :bool
           }}
        end

        def field_def("isParentGroup") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isParentGroup",
             kind: {:scalar, false},
             label: :optional,
             name: :isParentGroup,
             tag: 35,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isDefaultSubgroup) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDefaultSubgroup",
             kind: {:scalar, false},
             label: :optional,
             name: :isDefaultSubgroup,
             tag: 36,
             type: :bool
           }}
        end

        def field_def("isDefaultSubgroup") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isDefaultSubgroup",
             kind: {:scalar, false},
             label: :optional,
             name: :isDefaultSubgroup,
             tag: 36,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:parentGroupID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "parentGroupID",
             kind: {:scalar, ""},
             label: :optional,
             name: :parentGroupID,
             tag: 37,
             type: :string
           }}
        end

        def field_def("parentGroupID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "parentGroupID",
             kind: {:scalar, ""},
             label: :optional,
             name: :parentGroupID,
             tag: 37,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:displayName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "displayName",
             kind: {:scalar, ""},
             label: :optional,
             name: :displayName,
             tag: 38,
             type: :string
           }}
        end

        def field_def("displayName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "displayName",
             kind: {:scalar, ""},
             label: :optional,
             name: :displayName,
             tag: 38,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:pnJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pnJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :pnJID,
             tag: 39,
             type: :string
           }}
        end

        def field_def("pnJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pnJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :pnJID,
             tag: 39,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:shareOwnPn) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shareOwnPn",
             kind: {:scalar, false},
             label: :optional,
             name: :shareOwnPn,
             tag: 40,
             type: :bool
           }}
        end

        def field_def("shareOwnPn") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "shareOwnPn",
             kind: {:scalar, false},
             label: :optional,
             name: :shareOwnPn,
             tag: 40,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:pnhDuplicateLidThread) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pnhDuplicateLidThread",
             kind: {:scalar, false},
             label: :optional,
             name: :pnhDuplicateLidThread,
             tag: 41,
             type: :bool
           }}
        end

        def field_def("pnhDuplicateLidThread") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "pnhDuplicateLidThread",
             kind: {:scalar, false},
             label: :optional,
             name: :pnhDuplicateLidThread,
             tag: 41,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:lidJID) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :lidJID,
             tag: 42,
             type: :string
           }}
        end

        def field_def("lidJID") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidJID",
             kind: {:scalar, ""},
             label: :optional,
             name: :lidJID,
             tag: 42,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:username) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "username",
             kind: {:scalar, ""},
             label: :optional,
             name: :username,
             tag: 43,
             type: :string
           }}
        end

        def field_def("username") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "username",
             kind: {:scalar, ""},
             label: :optional,
             name: :username,
             tag: 43,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:lidOriginType) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidOriginType",
             kind: {:scalar, ""},
             label: :optional,
             name: :lidOriginType,
             tag: 44,
             type: :string
           }}
        end

        def field_def("lidOriginType") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "lidOriginType",
             kind: {:scalar, ""},
             label: :optional,
             name: :lidOriginType,
             tag: 44,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:commentsCount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "commentsCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :commentsCount,
             tag: 45,
             type: :uint32
           }}
        end

        def field_def("commentsCount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "commentsCount",
             kind: {:scalar, 0},
             label: :optional,
             name: :commentsCount,
             tag: 45,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:locked) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "locked",
             kind: {:scalar, false},
             label: :optional,
             name: :locked,
             tag: 46,
             type: :bool
           }}
        end

        def field_def("locked") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "locked",
             kind: {:scalar, false},
             label: :optional,
             name: :locked,
             tag: 46,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:systemMessageToInsert) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "systemMessageToInsert",
             kind: {:scalar, :E2EE_MSG},
             label: :optional,
             name: :systemMessageToInsert,
             tag: 47,
             type: {:enum, WAWebProtobufsHistorySync.PrivacySystemMessage}
           }}
        end

        def field_def("systemMessageToInsert") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "systemMessageToInsert",
             kind: {:scalar, :E2EE_MSG},
             label: :optional,
             name: :systemMessageToInsert,
             tag: 47,
             type: {:enum, WAWebProtobufsHistorySync.PrivacySystemMessage}
           }}
        end

        []
      ),
      (
        def field_def(:capiCreatedGroup) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "capiCreatedGroup",
             kind: {:scalar, false},
             label: :optional,
             name: :capiCreatedGroup,
             tag: 48,
             type: :bool
           }}
        end

        def field_def("capiCreatedGroup") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "capiCreatedGroup",
             kind: {:scalar, false},
             label: :optional,
             name: :capiCreatedGroup,
             tag: 48,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:accountLid) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accountLid",
             kind: {:scalar, ""},
             label: :optional,
             name: :accountLid,
             tag: 49,
             type: :string
           }}
        end

        def field_def("accountLid") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "accountLid",
             kind: {:scalar, ""},
             label: :optional,
             name: :accountLid,
             tag: 49,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:limitSharing) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharing",
             kind: {:scalar, false},
             label: :optional,
             name: :limitSharing,
             tag: 50,
             type: :bool
           }}
        end

        def field_def("limitSharing") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharing",
             kind: {:scalar, false},
             label: :optional,
             name: :limitSharing,
             tag: 50,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:limitSharingSettingTimestamp) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingSettingTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :limitSharingSettingTimestamp,
             tag: 51,
             type: :int64
           }}
        end

        def field_def("limitSharingSettingTimestamp") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingSettingTimestamp",
             kind: {:scalar, 0},
             label: :optional,
             name: :limitSharingSettingTimestamp,
             tag: 51,
             type: :int64
           }}
        end

        []
      ),
      (
        def field_def(:limitSharingTrigger) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingTrigger",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :limitSharingTrigger,
             tag: 52,
             type: {:enum, WACommon.LimitSharing.Trigger}
           }}
        end

        def field_def("limitSharingTrigger") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingTrigger",
             kind: {:scalar, :UNKNOWN},
             label: :optional,
             name: :limitSharingTrigger,
             tag: 52,
             type: {:enum, WACommon.LimitSharing.Trigger}
           }}
        end

        []
      ),
      (
        def field_def(:limitSharingInitiatedByMe) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingInitiatedByMe",
             kind: {:scalar, false},
             label: :optional,
             name: :limitSharingInitiatedByMe,
             tag: 53,
             type: :bool
           }}
        end

        def field_def("limitSharingInitiatedByMe") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "limitSharingInitiatedByMe",
             kind: {:scalar, false},
             label: :optional,
             name: :limitSharingInitiatedByMe,
             tag: 53,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:maibaAiThreadEnabled) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "maibaAiThreadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :maibaAiThreadEnabled,
             tag: 54,
             type: :bool
           }}
        end

        def field_def("maibaAiThreadEnabled") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "maibaAiThreadEnabled",
             kind: {:scalar, false},
             label: :optional,
             name: :maibaAiThreadEnabled,
             tag: 54,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isMarketingMessageThread) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isMarketingMessageThread",
             kind: {:scalar, false},
             label: :optional,
             name: :isMarketingMessageThread,
             tag: 55,
             type: :bool
           }}
        end

        def field_def("isMarketingMessageThread") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isMarketingMessageThread",
             kind: {:scalar, false},
             label: :optional,
             name: :isMarketingMessageThread,
             tag: 55,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:isSenderNewAccount) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSenderNewAccount",
             kind: {:scalar, false},
             label: :optional,
             name: :isSenderNewAccount,
             tag: 56,
             type: :bool
           }}
        end

        def field_def("isSenderNewAccount") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSenderNewAccount",
             kind: {:scalar, false},
             label: :optional,
             name: :isSenderNewAccount,
             tag: 56,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:afterReadDuration) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "afterReadDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :afterReadDuration,
             tag: 57,
             type: :uint32
           }}
        end

        def field_def("afterReadDuration") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "afterReadDuration",
             kind: {:scalar, 0},
             label: :optional,
             name: :afterReadDuration,
             tag: 57,
             type: :uint32
           }}
        end

        []
      ),
      (
        def field_def(:isSenderSuspicious) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSenderSuspicious",
             kind: {:scalar, false},
             label: :optional,
             name: :isSenderSuspicious,
             tag: 58,
             type: :bool
           }}
        end

        def field_def("isSenderSuspicious") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "isSenderSuspicious",
             kind: {:scalar, false},
             label: :optional,
             name: :isSenderSuspicious,
             tag: 58,
             type: :bool
           }}
        end

        []
      ),
      (
        def field_def(:appealStatus) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appealStatus",
             kind: {:scalar, :NO_APPEAL},
             label: :optional,
             name: :appealStatus,
             tag: 59,
             type: {:enum, WAWebProtobufsHistorySync.Conversation.GroupAppealStatus}
           }}
        end

        def field_def("appealStatus") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appealStatus",
             kind: {:scalar, :NO_APPEAL},
             label: :optional,
             name: :appealStatus,
             tag: 59,
             type: {:enum, WAWebProtobufsHistorySync.Conversation.GroupAppealStatus}
           }}
        end

        []
      ),
      (
        def field_def(:appealUpdateTime) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appealUpdateTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :appealUpdateTime,
             tag: 60,
             type: :uint64
           }}
        end

        def field_def("appealUpdateTime") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "appealUpdateTime",
             kind: {:scalar, 0},
             label: :optional,
             name: :appealUpdateTime,
             tag: 60,
             type: :uint64
           }}
        end

        []
      ),
      (
        def field_def(:authAgentParentCompanyName) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "authAgentParentCompanyName",
             kind: {:scalar, ""},
             label: :optional,
             name: :authAgentParentCompanyName,
             tag: 61,
             type: :string
           }}
        end

        def field_def("authAgentParentCompanyName") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "authAgentParentCompanyName",
             kind: {:scalar, ""},
             label: :optional,
             name: :authAgentParentCompanyName,
             tag: 61,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:authAgentObaPhoneNumber) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "authAgentObaPhoneNumber",
             kind: {:scalar, ""},
             label: :optional,
             name: :authAgentObaPhoneNumber,
             tag: 62,
             type: :string
           }}
        end

        def field_def("authAgentObaPhoneNumber") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "authAgentObaPhoneNumber",
             kind: {:scalar, ""},
             label: :optional,
             name: :authAgentObaPhoneNumber,
             tag: 62,
             type: :string
           }}
        end

        []
      ),
      (
        def field_def(:identityVerification) do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "identityVerification",
             kind: {:scalar, nil},
             label: :optional,
             name: :identityVerification,
             tag: 63,
             type: {:message, WAWebProtobufsHistorySync.IdentityVerificationState}
           }}
        end

        def field_def("identityVerification") do
          {:ok,
           %{
             __struct__: Protox.Field,
             json_name: "identityVerification",
             kind: {:scalar, nil},
             label: :optional,
             name: :identityVerification,
             tag: 63,
             type: {:message, WAWebProtobufsHistorySync.IdentityVerificationState}
           }}
        end

        []
      ),
      def field_def(_) do
        {:error, :no_such_field}
      end
    ]
  )

  (
    @spec unknown_fields(struct) :: [{non_neg_integer, Protox.Types.tag(), binary}]
    def unknown_fields(msg) do
      msg.__uf__
    end

    @spec unknown_fields_name() :: :__uf__
    def unknown_fields_name() do
      :__uf__
    end

    @spec clear_unknown_fields(struct) :: struct
    def clear_unknown_fields(msg) do
      struct!(msg, [{unknown_fields_name(), []}])
    end
  )

  (
    @spec required_fields() :: [:ID]
    def required_fields() do
      [:ID]
    end
  )

  (
    @spec syntax() :: atom()
    def syntax() do
      :proto2
    end
  )

  [
    @spec(default(atom) :: {:ok, boolean | integer | String.t() | float} | {:error, atom}),
    def default(:ID) do
      {:ok, ""}
    end,
    def default(:messages) do
      {:error, :no_default_value}
    end,
    def default(:newJID) do
      {:ok, ""}
    end,
    def default(:oldJID) do
      {:ok, ""}
    end,
    def default(:lastMsgTimestamp) do
      {:ok, 0}
    end,
    def default(:unreadCount) do
      {:ok, 0}
    end,
    def default(:readOnly) do
      {:ok, false}
    end,
    def default(:endOfHistoryTransfer) do
      {:ok, false}
    end,
    def default(:ephemeralExpiration) do
      {:ok, 0}
    end,
    def default(:ephemeralSettingTimestamp) do
      {:ok, 0}
    end,
    def default(:endOfHistoryTransferType) do
      {:ok, :COMPLETE_BUT_MORE_MESSAGES_REMAIN_ON_PRIMARY}
    end,
    def default(:conversationTimestamp) do
      {:ok, 0}
    end,
    def default(:name) do
      {:ok, ""}
    end,
    def default(:pHash) do
      {:ok, ""}
    end,
    def default(:notSpam) do
      {:ok, false}
    end,
    def default(:archived) do
      {:ok, false}
    end,
    def default(:disappearingMode) do
      {:ok, nil}
    end,
    def default(:unreadMentionCount) do
      {:ok, 0}
    end,
    def default(:markedAsUnread) do
      {:ok, false}
    end,
    def default(:participant) do
      {:error, :no_default_value}
    end,
    def default(:tcToken) do
      {:ok, ""}
    end,
    def default(:tcTokenTimestamp) do
      {:ok, 0}
    end,
    def default(:contactPrimaryIdentityKey) do
      {:ok, ""}
    end,
    def default(:pinned) do
      {:ok, 0}
    end,
    def default(:muteEndTime) do
      {:ok, 0}
    end,
    def default(:wallpaper) do
      {:ok, nil}
    end,
    def default(:mediaVisibility) do
      {:ok, :DEFAULT}
    end,
    def default(:tcTokenSenderTimestamp) do
      {:ok, 0}
    end,
    def default(:suspended) do
      {:ok, false}
    end,
    def default(:terminated) do
      {:ok, false}
    end,
    def default(:createdAt) do
      {:ok, 0}
    end,
    def default(:createdBy) do
      {:ok, ""}
    end,
    def default(:description) do
      {:ok, ""}
    end,
    def default(:support) do
      {:ok, false}
    end,
    def default(:isParentGroup) do
      {:ok, false}
    end,
    def default(:isDefaultSubgroup) do
      {:ok, false}
    end,
    def default(:parentGroupID) do
      {:ok, ""}
    end,
    def default(:displayName) do
      {:ok, ""}
    end,
    def default(:pnJID) do
      {:ok, ""}
    end,
    def default(:shareOwnPn) do
      {:ok, false}
    end,
    def default(:pnhDuplicateLidThread) do
      {:ok, false}
    end,
    def default(:lidJID) do
      {:ok, ""}
    end,
    def default(:username) do
      {:ok, ""}
    end,
    def default(:lidOriginType) do
      {:ok, ""}
    end,
    def default(:commentsCount) do
      {:ok, 0}
    end,
    def default(:locked) do
      {:ok, false}
    end,
    def default(:systemMessageToInsert) do
      {:ok, :E2EE_MSG}
    end,
    def default(:capiCreatedGroup) do
      {:ok, false}
    end,
    def default(:accountLid) do
      {:ok, ""}
    end,
    def default(:limitSharing) do
      {:ok, false}
    end,
    def default(:limitSharingSettingTimestamp) do
      {:ok, 0}
    end,
    def default(:limitSharingTrigger) do
      {:ok, :UNKNOWN}
    end,
    def default(:limitSharingInitiatedByMe) do
      {:ok, false}
    end,
    def default(:maibaAiThreadEnabled) do
      {:ok, false}
    end,
    def default(:isMarketingMessageThread) do
      {:ok, false}
    end,
    def default(:isSenderNewAccount) do
      {:ok, false}
    end,
    def default(:afterReadDuration) do
      {:ok, 0}
    end,
    def default(:isSenderSuspicious) do
      {:ok, false}
    end,
    def default(:appealStatus) do
      {:ok, :NO_APPEAL}
    end,
    def default(:appealUpdateTime) do
      {:ok, 0}
    end,
    def default(:authAgentParentCompanyName) do
      {:ok, ""}
    end,
    def default(:authAgentObaPhoneNumber) do
      {:ok, ""}
    end,
    def default(:identityVerification) do
      {:ok, nil}
    end,
    def default(_) do
      {:error, :no_such_field}
    end
  ]

  (
    @spec file_options() :: struct()
    def file_options() do
      file_options = %{
        __struct__: Protox.Google.Protobuf.FileOptions,
        __uf__: [],
        cc_enable_arenas: nil,
        cc_generic_services: nil,
        csharp_namespace: nil,
        deprecated: nil,
        go_package: "go.mau.fi/whatsmeow/proto/waHistorySync",
        java_generate_equals_and_hash: nil,
        java_generic_services: nil,
        java_multiple_files: nil,
        java_outer_classname: nil,
        java_package: nil,
        java_string_check_utf8: nil,
        objc_class_prefix: nil,
        optimize_for: nil,
        php_class_prefix: nil,
        php_generic_services: nil,
        php_metadata_namespace: nil,
        php_namespace: nil,
        py_generic_services: nil,
        ruby_package: nil,
        swift_prefix: nil,
        uninterpreted_option: []
      }

      case function_exported?(Google.Protobuf.FileOptions, :decode!, 1) do
        true ->
          bytes =
            file_options |> Protox.Google.Protobuf.FileOptions.encode!() |> :binary.list_to_bin()

          apply(Google.Protobuf.FileOptions, :decode!, [bytes])

        false ->
          file_options
      end
    end
  )

  @type t :: %__MODULE__{}
end
