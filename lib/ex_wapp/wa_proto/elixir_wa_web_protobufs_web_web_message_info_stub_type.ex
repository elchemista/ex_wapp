# credo:disable-for-this-file
defmodule WAWebProtobufsWeb.WebMessageInfo.StubType do
  @moduledoc false
  (
    defstruct []

    (
      @spec default() :: :UNKNOWN
      def default() do
        :UNKNOWN
      end
    )

    @spec encode(atom() | String.t()) :: integer() | atom()
    [
      (
        def encode(:UNKNOWN) do
          0
        end

        def encode("UNKNOWN") do
          0
        end
      ),
      (
        def encode(:REVOKE) do
          1
        end

        def encode("REVOKE") do
          1
        end
      ),
      (
        def encode(:CIPHERTEXT) do
          2
        end

        def encode("CIPHERTEXT") do
          2
        end
      ),
      (
        def encode(:FUTUREPROOF) do
          3
        end

        def encode("FUTUREPROOF") do
          3
        end
      ),
      (
        def encode(:NON_VERIFIED_TRANSITION) do
          4
        end

        def encode("NON_VERIFIED_TRANSITION") do
          4
        end
      ),
      (
        def encode(:UNVERIFIED_TRANSITION) do
          5
        end

        def encode("UNVERIFIED_TRANSITION") do
          5
        end
      ),
      (
        def encode(:VERIFIED_TRANSITION) do
          6
        end

        def encode("VERIFIED_TRANSITION") do
          6
        end
      ),
      (
        def encode(:VERIFIED_LOW_UNKNOWN) do
          7
        end

        def encode("VERIFIED_LOW_UNKNOWN") do
          7
        end
      ),
      (
        def encode(:VERIFIED_HIGH) do
          8
        end

        def encode("VERIFIED_HIGH") do
          8
        end
      ),
      (
        def encode(:VERIFIED_INITIAL_UNKNOWN) do
          9
        end

        def encode("VERIFIED_INITIAL_UNKNOWN") do
          9
        end
      ),
      (
        def encode(:VERIFIED_INITIAL_LOW) do
          10
        end

        def encode("VERIFIED_INITIAL_LOW") do
          10
        end
      ),
      (
        def encode(:VERIFIED_INITIAL_HIGH) do
          11
        end

        def encode("VERIFIED_INITIAL_HIGH") do
          11
        end
      ),
      (
        def encode(:VERIFIED_TRANSITION_ANY_TO_NONE) do
          12
        end

        def encode("VERIFIED_TRANSITION_ANY_TO_NONE") do
          12
        end
      ),
      (
        def encode(:VERIFIED_TRANSITION_ANY_TO_HIGH) do
          13
        end

        def encode("VERIFIED_TRANSITION_ANY_TO_HIGH") do
          13
        end
      ),
      (
        def encode(:VERIFIED_TRANSITION_HIGH_TO_LOW) do
          14
        end

        def encode("VERIFIED_TRANSITION_HIGH_TO_LOW") do
          14
        end
      ),
      (
        def encode(:VERIFIED_TRANSITION_HIGH_TO_UNKNOWN) do
          15
        end

        def encode("VERIFIED_TRANSITION_HIGH_TO_UNKNOWN") do
          15
        end
      ),
      (
        def encode(:VERIFIED_TRANSITION_UNKNOWN_TO_LOW) do
          16
        end

        def encode("VERIFIED_TRANSITION_UNKNOWN_TO_LOW") do
          16
        end
      ),
      (
        def encode(:VERIFIED_TRANSITION_LOW_TO_UNKNOWN) do
          17
        end

        def encode("VERIFIED_TRANSITION_LOW_TO_UNKNOWN") do
          17
        end
      ),
      (
        def encode(:VERIFIED_TRANSITION_NONE_TO_LOW) do
          18
        end

        def encode("VERIFIED_TRANSITION_NONE_TO_LOW") do
          18
        end
      ),
      (
        def encode(:VERIFIED_TRANSITION_NONE_TO_UNKNOWN) do
          19
        end

        def encode("VERIFIED_TRANSITION_NONE_TO_UNKNOWN") do
          19
        end
      ),
      (
        def encode(:GROUP_CREATE) do
          20
        end

        def encode("GROUP_CREATE") do
          20
        end
      ),
      (
        def encode(:GROUP_CHANGE_SUBJECT) do
          21
        end

        def encode("GROUP_CHANGE_SUBJECT") do
          21
        end
      ),
      (
        def encode(:GROUP_CHANGE_ICON) do
          22
        end

        def encode("GROUP_CHANGE_ICON") do
          22
        end
      ),
      (
        def encode(:GROUP_CHANGE_INVITE_LINK) do
          23
        end

        def encode("GROUP_CHANGE_INVITE_LINK") do
          23
        end
      ),
      (
        def encode(:GROUP_CHANGE_DESCRIPTION) do
          24
        end

        def encode("GROUP_CHANGE_DESCRIPTION") do
          24
        end
      ),
      (
        def encode(:GROUP_CHANGE_RESTRICT) do
          25
        end

        def encode("GROUP_CHANGE_RESTRICT") do
          25
        end
      ),
      (
        def encode(:GROUP_CHANGE_ANNOUNCE) do
          26
        end

        def encode("GROUP_CHANGE_ANNOUNCE") do
          26
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_ADD) do
          27
        end

        def encode("GROUP_PARTICIPANT_ADD") do
          27
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_REMOVE) do
          28
        end

        def encode("GROUP_PARTICIPANT_REMOVE") do
          28
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_PROMOTE) do
          29
        end

        def encode("GROUP_PARTICIPANT_PROMOTE") do
          29
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_DEMOTE) do
          30
        end

        def encode("GROUP_PARTICIPANT_DEMOTE") do
          30
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_INVITE) do
          31
        end

        def encode("GROUP_PARTICIPANT_INVITE") do
          31
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_LEAVE) do
          32
        end

        def encode("GROUP_PARTICIPANT_LEAVE") do
          32
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_CHANGE_NUMBER) do
          33
        end

        def encode("GROUP_PARTICIPANT_CHANGE_NUMBER") do
          33
        end
      ),
      (
        def encode(:BROADCAST_CREATE) do
          34
        end

        def encode("BROADCAST_CREATE") do
          34
        end
      ),
      (
        def encode(:BROADCAST_ADD) do
          35
        end

        def encode("BROADCAST_ADD") do
          35
        end
      ),
      (
        def encode(:BROADCAST_REMOVE) do
          36
        end

        def encode("BROADCAST_REMOVE") do
          36
        end
      ),
      (
        def encode(:GENERIC_NOTIFICATION) do
          37
        end

        def encode("GENERIC_NOTIFICATION") do
          37
        end
      ),
      (
        def encode(:E2E_IDENTITY_CHANGED) do
          38
        end

        def encode("E2E_IDENTITY_CHANGED") do
          38
        end
      ),
      (
        def encode(:E2E_ENCRYPTED) do
          39
        end

        def encode("E2E_ENCRYPTED") do
          39
        end
      ),
      (
        def encode(:CALL_MISSED_VOICE) do
          40
        end

        def encode("CALL_MISSED_VOICE") do
          40
        end
      ),
      (
        def encode(:CALL_MISSED_VIDEO) do
          41
        end

        def encode("CALL_MISSED_VIDEO") do
          41
        end
      ),
      (
        def encode(:INDIVIDUAL_CHANGE_NUMBER) do
          42
        end

        def encode("INDIVIDUAL_CHANGE_NUMBER") do
          42
        end
      ),
      (
        def encode(:GROUP_DELETE) do
          43
        end

        def encode("GROUP_DELETE") do
          43
        end
      ),
      (
        def encode(:GROUP_ANNOUNCE_MODE_MESSAGE_BOUNCE) do
          44
        end

        def encode("GROUP_ANNOUNCE_MODE_MESSAGE_BOUNCE") do
          44
        end
      ),
      (
        def encode(:CALL_MISSED_GROUP_VOICE) do
          45
        end

        def encode("CALL_MISSED_GROUP_VOICE") do
          45
        end
      ),
      (
        def encode(:CALL_MISSED_GROUP_VIDEO) do
          46
        end

        def encode("CALL_MISSED_GROUP_VIDEO") do
          46
        end
      ),
      (
        def encode(:PAYMENT_CIPHERTEXT) do
          47
        end

        def encode("PAYMENT_CIPHERTEXT") do
          47
        end
      ),
      (
        def encode(:PAYMENT_FUTUREPROOF) do
          48
        end

        def encode("PAYMENT_FUTUREPROOF") do
          48
        end
      ),
      (
        def encode(:PAYMENT_TRANSACTION_STATUS_UPDATE_FAILED) do
          49
        end

        def encode("PAYMENT_TRANSACTION_STATUS_UPDATE_FAILED") do
          49
        end
      ),
      (
        def encode(:PAYMENT_TRANSACTION_STATUS_UPDATE_REFUNDED) do
          50
        end

        def encode("PAYMENT_TRANSACTION_STATUS_UPDATE_REFUNDED") do
          50
        end
      ),
      (
        def encode(:PAYMENT_TRANSACTION_STATUS_UPDATE_REFUND_FAILED) do
          51
        end

        def encode("PAYMENT_TRANSACTION_STATUS_UPDATE_REFUND_FAILED") do
          51
        end
      ),
      (
        def encode(:PAYMENT_TRANSACTION_STATUS_RECEIVER_PENDING_SETUP) do
          52
        end

        def encode("PAYMENT_TRANSACTION_STATUS_RECEIVER_PENDING_SETUP") do
          52
        end
      ),
      (
        def encode(:PAYMENT_TRANSACTION_STATUS_RECEIVER_SUCCESS_AFTER_HICCUP) do
          53
        end

        def encode("PAYMENT_TRANSACTION_STATUS_RECEIVER_SUCCESS_AFTER_HICCUP") do
          53
        end
      ),
      (
        def encode(:PAYMENT_ACTION_ACCOUNT_SETUP_REMINDER) do
          54
        end

        def encode("PAYMENT_ACTION_ACCOUNT_SETUP_REMINDER") do
          54
        end
      ),
      (
        def encode(:PAYMENT_ACTION_SEND_PAYMENT_REMINDER) do
          55
        end

        def encode("PAYMENT_ACTION_SEND_PAYMENT_REMINDER") do
          55
        end
      ),
      (
        def encode(:PAYMENT_ACTION_SEND_PAYMENT_INVITATION) do
          56
        end

        def encode("PAYMENT_ACTION_SEND_PAYMENT_INVITATION") do
          56
        end
      ),
      (
        def encode(:PAYMENT_ACTION_REQUEST_DECLINED) do
          57
        end

        def encode("PAYMENT_ACTION_REQUEST_DECLINED") do
          57
        end
      ),
      (
        def encode(:PAYMENT_ACTION_REQUEST_EXPIRED) do
          58
        end

        def encode("PAYMENT_ACTION_REQUEST_EXPIRED") do
          58
        end
      ),
      (
        def encode(:PAYMENT_ACTION_REQUEST_CANCELLED) do
          59
        end

        def encode("PAYMENT_ACTION_REQUEST_CANCELLED") do
          59
        end
      ),
      (
        def encode(:BIZ_VERIFIED_TRANSITION_TOP_TO_BOTTOM) do
          60
        end

        def encode("BIZ_VERIFIED_TRANSITION_TOP_TO_BOTTOM") do
          60
        end
      ),
      (
        def encode(:BIZ_VERIFIED_TRANSITION_BOTTOM_TO_TOP) do
          61
        end

        def encode("BIZ_VERIFIED_TRANSITION_BOTTOM_TO_TOP") do
          61
        end
      ),
      (
        def encode(:BIZ_INTRO_TOP) do
          62
        end

        def encode("BIZ_INTRO_TOP") do
          62
        end
      ),
      (
        def encode(:BIZ_INTRO_BOTTOM) do
          63
        end

        def encode("BIZ_INTRO_BOTTOM") do
          63
        end
      ),
      (
        def encode(:BIZ_NAME_CHANGE) do
          64
        end

        def encode("BIZ_NAME_CHANGE") do
          64
        end
      ),
      (
        def encode(:BIZ_MOVE_TO_CONSUMER_APP) do
          65
        end

        def encode("BIZ_MOVE_TO_CONSUMER_APP") do
          65
        end
      ),
      (
        def encode(:BIZ_TWO_TIER_MIGRATION_TOP) do
          66
        end

        def encode("BIZ_TWO_TIER_MIGRATION_TOP") do
          66
        end
      ),
      (
        def encode(:BIZ_TWO_TIER_MIGRATION_BOTTOM) do
          67
        end

        def encode("BIZ_TWO_TIER_MIGRATION_BOTTOM") do
          67
        end
      ),
      (
        def encode(:OVERSIZED) do
          68
        end

        def encode("OVERSIZED") do
          68
        end
      ),
      (
        def encode(:GROUP_CHANGE_NO_FREQUENTLY_FORWARDED) do
          69
        end

        def encode("GROUP_CHANGE_NO_FREQUENTLY_FORWARDED") do
          69
        end
      ),
      (
        def encode(:GROUP_V4_ADD_INVITE_SENT) do
          70
        end

        def encode("GROUP_V4_ADD_INVITE_SENT") do
          70
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_ADD_REQUEST_JOIN) do
          71
        end

        def encode("GROUP_PARTICIPANT_ADD_REQUEST_JOIN") do
          71
        end
      ),
      (
        def encode(:CHANGE_EPHEMERAL_SETTING) do
          72
        end

        def encode("CHANGE_EPHEMERAL_SETTING") do
          72
        end
      ),
      (
        def encode(:E2E_DEVICE_CHANGED) do
          73
        end

        def encode("E2E_DEVICE_CHANGED") do
          73
        end
      ),
      (
        def encode(:VIEWED_ONCE) do
          74
        end

        def encode("VIEWED_ONCE") do
          74
        end
      ),
      (
        def encode(:E2E_ENCRYPTED_NOW) do
          75
        end

        def encode("E2E_ENCRYPTED_NOW") do
          75
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_TO_BSP_PREMISE) do
          76
        end

        def encode("BLUE_MSG_BSP_FB_TO_BSP_PREMISE") do
          76
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_TO_SELF_FB) do
          77
        end

        def encode("BLUE_MSG_BSP_FB_TO_SELF_FB") do
          77
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_TO_SELF_PREMISE) do
          78
        end

        def encode("BLUE_MSG_BSP_FB_TO_SELF_PREMISE") do
          78
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_UNVERIFIED) do
          79
        end

        def encode("BLUE_MSG_BSP_FB_UNVERIFIED") do
          79
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED) do
          80
        end

        def encode("BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED") do
          80
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_VERIFIED) do
          81
        end

        def encode("BLUE_MSG_BSP_FB_VERIFIED") do
          81
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED) do
          82
        end

        def encode("BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED") do
          82
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_PREMISE_TO_SELF_PREMISE) do
          83
        end

        def encode("BLUE_MSG_BSP_PREMISE_TO_SELF_PREMISE") do
          83
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_PREMISE_UNVERIFIED) do
          84
        end

        def encode("BLUE_MSG_BSP_PREMISE_UNVERIFIED") do
          84
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_PREMISE_UNVERIFIED_TO_SELF_PREMISE_VERIFIED) do
          85
        end

        def encode("BLUE_MSG_BSP_PREMISE_UNVERIFIED_TO_SELF_PREMISE_VERIFIED") do
          85
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_PREMISE_VERIFIED) do
          86
        end

        def encode("BLUE_MSG_BSP_PREMISE_VERIFIED") do
          86
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_PREMISE_VERIFIED_TO_SELF_PREMISE_UNVERIFIED) do
          87
        end

        def encode("BLUE_MSG_BSP_PREMISE_VERIFIED_TO_SELF_PREMISE_UNVERIFIED") do
          87
        end
      ),
      (
        def encode(:BLUE_MSG_CONSUMER_TO_BSP_FB_UNVERIFIED) do
          88
        end

        def encode("BLUE_MSG_CONSUMER_TO_BSP_FB_UNVERIFIED") do
          88
        end
      ),
      (
        def encode(:BLUE_MSG_CONSUMER_TO_BSP_PREMISE_UNVERIFIED) do
          89
        end

        def encode("BLUE_MSG_CONSUMER_TO_BSP_PREMISE_UNVERIFIED") do
          89
        end
      ),
      (
        def encode(:BLUE_MSG_CONSUMER_TO_SELF_FB_UNVERIFIED) do
          90
        end

        def encode("BLUE_MSG_CONSUMER_TO_SELF_FB_UNVERIFIED") do
          90
        end
      ),
      (
        def encode(:BLUE_MSG_CONSUMER_TO_SELF_PREMISE_UNVERIFIED) do
          91
        end

        def encode("BLUE_MSG_CONSUMER_TO_SELF_PREMISE_UNVERIFIED") do
          91
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_FB_TO_BSP_PREMISE) do
          92
        end

        def encode("BLUE_MSG_SELF_FB_TO_BSP_PREMISE") do
          92
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_FB_TO_SELF_PREMISE) do
          93
        end

        def encode("BLUE_MSG_SELF_FB_TO_SELF_PREMISE") do
          93
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_FB_UNVERIFIED) do
          94
        end

        def encode("BLUE_MSG_SELF_FB_UNVERIFIED") do
          94
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED) do
          95
        end

        def encode("BLUE_MSG_SELF_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED") do
          95
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_FB_VERIFIED) do
          96
        end

        def encode("BLUE_MSG_SELF_FB_VERIFIED") do
          96
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED) do
          97
        end

        def encode("BLUE_MSG_SELF_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED") do
          97
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_PREMISE_TO_BSP_PREMISE) do
          98
        end

        def encode("BLUE_MSG_SELF_PREMISE_TO_BSP_PREMISE") do
          98
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_PREMISE_UNVERIFIED) do
          99
        end

        def encode("BLUE_MSG_SELF_PREMISE_UNVERIFIED") do
          99
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_PREMISE_VERIFIED) do
          100
        end

        def encode("BLUE_MSG_SELF_PREMISE_VERIFIED") do
          100
        end
      ),
      (
        def encode(:BLUE_MSG_TO_BSP_FB) do
          101
        end

        def encode("BLUE_MSG_TO_BSP_FB") do
          101
        end
      ),
      (
        def encode(:BLUE_MSG_TO_CONSUMER) do
          102
        end

        def encode("BLUE_MSG_TO_CONSUMER") do
          102
        end
      ),
      (
        def encode(:BLUE_MSG_TO_SELF_FB) do
          103
        end

        def encode("BLUE_MSG_TO_SELF_FB") do
          103
        end
      ),
      (
        def encode(:BLUE_MSG_UNVERIFIED_TO_BSP_FB_VERIFIED) do
          104
        end

        def encode("BLUE_MSG_UNVERIFIED_TO_BSP_FB_VERIFIED") do
          104
        end
      ),
      (
        def encode(:BLUE_MSG_UNVERIFIED_TO_BSP_PREMISE_VERIFIED) do
          105
        end

        def encode("BLUE_MSG_UNVERIFIED_TO_BSP_PREMISE_VERIFIED") do
          105
        end
      ),
      (
        def encode(:BLUE_MSG_UNVERIFIED_TO_SELF_FB_VERIFIED) do
          106
        end

        def encode("BLUE_MSG_UNVERIFIED_TO_SELF_FB_VERIFIED") do
          106
        end
      ),
      (
        def encode(:BLUE_MSG_UNVERIFIED_TO_VERIFIED) do
          107
        end

        def encode("BLUE_MSG_UNVERIFIED_TO_VERIFIED") do
          107
        end
      ),
      (
        def encode(:BLUE_MSG_VERIFIED_TO_BSP_FB_UNVERIFIED) do
          108
        end

        def encode("BLUE_MSG_VERIFIED_TO_BSP_FB_UNVERIFIED") do
          108
        end
      ),
      (
        def encode(:BLUE_MSG_VERIFIED_TO_BSP_PREMISE_UNVERIFIED) do
          109
        end

        def encode("BLUE_MSG_VERIFIED_TO_BSP_PREMISE_UNVERIFIED") do
          109
        end
      ),
      (
        def encode(:BLUE_MSG_VERIFIED_TO_SELF_FB_UNVERIFIED) do
          110
        end

        def encode("BLUE_MSG_VERIFIED_TO_SELF_FB_UNVERIFIED") do
          110
        end
      ),
      (
        def encode(:BLUE_MSG_VERIFIED_TO_UNVERIFIED) do
          111
        end

        def encode("BLUE_MSG_VERIFIED_TO_UNVERIFIED") do
          111
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED) do
          112
        end

        def encode("BLUE_MSG_BSP_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED") do
          112
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_FB_VERIFIED) do
          113
        end

        def encode("BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_FB_VERIFIED") do
          113
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED) do
          114
        end

        def encode("BLUE_MSG_BSP_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED") do
          114
        end
      ),
      (
        def encode(:BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_FB_UNVERIFIED) do
          115
        end

        def encode("BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_FB_UNVERIFIED") do
          115
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED) do
          116
        end

        def encode("BLUE_MSG_SELF_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED") do
          116
        end
      ),
      (
        def encode(:BLUE_MSG_SELF_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED) do
          117
        end

        def encode("BLUE_MSG_SELF_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED") do
          117
        end
      ),
      (
        def encode(:E2E_IDENTITY_UNAVAILABLE) do
          118
        end

        def encode("E2E_IDENTITY_UNAVAILABLE") do
          118
        end
      ),
      (
        def encode(:GROUP_CREATING) do
          119
        end

        def encode("GROUP_CREATING") do
          119
        end
      ),
      (
        def encode(:GROUP_CREATE_FAILED) do
          120
        end

        def encode("GROUP_CREATE_FAILED") do
          120
        end
      ),
      (
        def encode(:GROUP_BOUNCED) do
          121
        end

        def encode("GROUP_BOUNCED") do
          121
        end
      ),
      (
        def encode(:BLOCK_CONTACT) do
          122
        end

        def encode("BLOCK_CONTACT") do
          122
        end
      ),
      (
        def encode(:EPHEMERAL_SETTING_NOT_APPLIED) do
          123
        end

        def encode("EPHEMERAL_SETTING_NOT_APPLIED") do
          123
        end
      ),
      (
        def encode(:SYNC_FAILED) do
          124
        end

        def encode("SYNC_FAILED") do
          124
        end
      ),
      (
        def encode(:SYNCING) do
          125
        end

        def encode("SYNCING") do
          125
        end
      ),
      (
        def encode(:BIZ_PRIVACY_MODE_INIT_FB) do
          126
        end

        def encode("BIZ_PRIVACY_MODE_INIT_FB") do
          126
        end
      ),
      (
        def encode(:BIZ_PRIVACY_MODE_INIT_BSP) do
          127
        end

        def encode("BIZ_PRIVACY_MODE_INIT_BSP") do
          127
        end
      ),
      (
        def encode(:BIZ_PRIVACY_MODE_TO_FB) do
          128
        end

        def encode("BIZ_PRIVACY_MODE_TO_FB") do
          128
        end
      ),
      (
        def encode(:BIZ_PRIVACY_MODE_TO_BSP) do
          129
        end

        def encode("BIZ_PRIVACY_MODE_TO_BSP") do
          129
        end
      ),
      (
        def encode(:DISAPPEARING_MODE) do
          130
        end

        def encode("DISAPPEARING_MODE") do
          130
        end
      ),
      (
        def encode(:E2E_DEVICE_FETCH_FAILED) do
          131
        end

        def encode("E2E_DEVICE_FETCH_FAILED") do
          131
        end
      ),
      (
        def encode(:ADMIN_REVOKE) do
          132
        end

        def encode("ADMIN_REVOKE") do
          132
        end
      ),
      (
        def encode(:GROUP_INVITE_LINK_GROWTH_LOCKED) do
          133
        end

        def encode("GROUP_INVITE_LINK_GROWTH_LOCKED") do
          133
        end
      ),
      (
        def encode(:COMMUNITY_LINK_PARENT_GROUP) do
          134
        end

        def encode("COMMUNITY_LINK_PARENT_GROUP") do
          134
        end
      ),
      (
        def encode(:COMMUNITY_LINK_SIBLING_GROUP) do
          135
        end

        def encode("COMMUNITY_LINK_SIBLING_GROUP") do
          135
        end
      ),
      (
        def encode(:COMMUNITY_LINK_SUB_GROUP) do
          136
        end

        def encode("COMMUNITY_LINK_SUB_GROUP") do
          136
        end
      ),
      (
        def encode(:COMMUNITY_UNLINK_PARENT_GROUP) do
          137
        end

        def encode("COMMUNITY_UNLINK_PARENT_GROUP") do
          137
        end
      ),
      (
        def encode(:COMMUNITY_UNLINK_SIBLING_GROUP) do
          138
        end

        def encode("COMMUNITY_UNLINK_SIBLING_GROUP") do
          138
        end
      ),
      (
        def encode(:COMMUNITY_UNLINK_SUB_GROUP) do
          139
        end

        def encode("COMMUNITY_UNLINK_SUB_GROUP") do
          139
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_ACCEPT) do
          140
        end

        def encode("GROUP_PARTICIPANT_ACCEPT") do
          140
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_LINKED_GROUP_JOIN) do
          141
        end

        def encode("GROUP_PARTICIPANT_LINKED_GROUP_JOIN") do
          141
        end
      ),
      (
        def encode(:COMMUNITY_CREATE) do
          142
        end

        def encode("COMMUNITY_CREATE") do
          142
        end
      ),
      (
        def encode(:EPHEMERAL_KEEP_IN_CHAT) do
          143
        end

        def encode("EPHEMERAL_KEEP_IN_CHAT") do
          143
        end
      ),
      (
        def encode(:GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST) do
          144
        end

        def encode("GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST") do
          144
        end
      ),
      (
        def encode(:GROUP_MEMBERSHIP_JOIN_APPROVAL_MODE) do
          145
        end

        def encode("GROUP_MEMBERSHIP_JOIN_APPROVAL_MODE") do
          145
        end
      ),
      (
        def encode(:INTEGRITY_UNLINK_PARENT_GROUP) do
          146
        end

        def encode("INTEGRITY_UNLINK_PARENT_GROUP") do
          146
        end
      ),
      (
        def encode(:COMMUNITY_PARTICIPANT_PROMOTE) do
          147
        end

        def encode("COMMUNITY_PARTICIPANT_PROMOTE") do
          147
        end
      ),
      (
        def encode(:COMMUNITY_PARTICIPANT_DEMOTE) do
          148
        end

        def encode("COMMUNITY_PARTICIPANT_DEMOTE") do
          148
        end
      ),
      (
        def encode(:COMMUNITY_PARENT_GROUP_DELETED) do
          149
        end

        def encode("COMMUNITY_PARENT_GROUP_DELETED") do
          149
        end
      ),
      (
        def encode(:COMMUNITY_LINK_PARENT_GROUP_MEMBERSHIP_APPROVAL) do
          150
        end

        def encode("COMMUNITY_LINK_PARENT_GROUP_MEMBERSHIP_APPROVAL") do
          150
        end
      ),
      (
        def encode(:GROUP_PARTICIPANT_JOINED_GROUP_AND_PARENT_GROUP) do
          151
        end

        def encode("GROUP_PARTICIPANT_JOINED_GROUP_AND_PARENT_GROUP") do
          151
        end
      ),
      (
        def encode(:MASKED_THREAD_CREATED) do
          152
        end

        def encode("MASKED_THREAD_CREATED") do
          152
        end
      ),
      (
        def encode(:MASKED_THREAD_UNMASKED) do
          153
        end

        def encode("MASKED_THREAD_UNMASKED") do
          153
        end
      ),
      (
        def encode(:BIZ_CHAT_ASSIGNMENT) do
          154
        end

        def encode("BIZ_CHAT_ASSIGNMENT") do
          154
        end
      ),
      (
        def encode(:CHAT_PSA) do
          155
        end

        def encode("CHAT_PSA") do
          155
        end
      ),
      (
        def encode(:CHAT_POLL_CREATION_MESSAGE) do
          156
        end

        def encode("CHAT_POLL_CREATION_MESSAGE") do
          156
        end
      ),
      (
        def encode(:CAG_MASKED_THREAD_CREATED) do
          157
        end

        def encode("CAG_MASKED_THREAD_CREATED") do
          157
        end
      ),
      (
        def encode(:COMMUNITY_PARENT_GROUP_SUBJECT_CHANGED) do
          158
        end

        def encode("COMMUNITY_PARENT_GROUP_SUBJECT_CHANGED") do
          158
        end
      ),
      (
        def encode(:CAG_INVITE_AUTO_ADD) do
          159
        end

        def encode("CAG_INVITE_AUTO_ADD") do
          159
        end
      ),
      (
        def encode(:BIZ_CHAT_ASSIGNMENT_UNASSIGN) do
          160
        end

        def encode("BIZ_CHAT_ASSIGNMENT_UNASSIGN") do
          160
        end
      ),
      (
        def encode(:CAG_INVITE_AUTO_JOINED) do
          161
        end

        def encode("CAG_INVITE_AUTO_JOINED") do
          161
        end
      ),
      (
        def encode(:SCHEDULED_CALL_START_MESSAGE) do
          162
        end

        def encode("SCHEDULED_CALL_START_MESSAGE") do
          162
        end
      ),
      (
        def encode(:COMMUNITY_INVITE_RICH) do
          163
        end

        def encode("COMMUNITY_INVITE_RICH") do
          163
        end
      ),
      (
        def encode(:COMMUNITY_INVITE_AUTO_ADD_RICH) do
          164
        end

        def encode("COMMUNITY_INVITE_AUTO_ADD_RICH") do
          164
        end
      ),
      (
        def encode(:SUB_GROUP_INVITE_RICH) do
          165
        end

        def encode("SUB_GROUP_INVITE_RICH") do
          165
        end
      ),
      (
        def encode(:SUB_GROUP_PARTICIPANT_ADD_RICH) do
          166
        end

        def encode("SUB_GROUP_PARTICIPANT_ADD_RICH") do
          166
        end
      ),
      (
        def encode(:COMMUNITY_LINK_PARENT_GROUP_RICH) do
          167
        end

        def encode("COMMUNITY_LINK_PARENT_GROUP_RICH") do
          167
        end
      ),
      (
        def encode(:COMMUNITY_PARTICIPANT_ADD_RICH) do
          168
        end

        def encode("COMMUNITY_PARTICIPANT_ADD_RICH") do
          168
        end
      ),
      (
        def encode(:SILENCED_UNKNOWN_CALLER_AUDIO) do
          169
        end

        def encode("SILENCED_UNKNOWN_CALLER_AUDIO") do
          169
        end
      ),
      (
        def encode(:SILENCED_UNKNOWN_CALLER_VIDEO) do
          170
        end

        def encode("SILENCED_UNKNOWN_CALLER_VIDEO") do
          170
        end
      ),
      (
        def encode(:GROUP_MEMBER_ADD_MODE) do
          171
        end

        def encode("GROUP_MEMBER_ADD_MODE") do
          171
        end
      ),
      (
        def encode(:GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST_NON_ADMIN_ADD) do
          172
        end

        def encode("GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST_NON_ADMIN_ADD") do
          172
        end
      ),
      (
        def encode(:COMMUNITY_CHANGE_DESCRIPTION) do
          173
        end

        def encode("COMMUNITY_CHANGE_DESCRIPTION") do
          173
        end
      ),
      (
        def encode(:SENDER_INVITE) do
          174
        end

        def encode("SENDER_INVITE") do
          174
        end
      ),
      (
        def encode(:RECEIVER_INVITE) do
          175
        end

        def encode("RECEIVER_INVITE") do
          175
        end
      ),
      (
        def encode(:COMMUNITY_ALLOW_MEMBER_ADDED_GROUPS) do
          176
        end

        def encode("COMMUNITY_ALLOW_MEMBER_ADDED_GROUPS") do
          176
        end
      ),
      (
        def encode(:PINNED_MESSAGE_IN_CHAT) do
          177
        end

        def encode("PINNED_MESSAGE_IN_CHAT") do
          177
        end
      ),
      (
        def encode(:PAYMENT_INVITE_SETUP_INVITER) do
          178
        end

        def encode("PAYMENT_INVITE_SETUP_INVITER") do
          178
        end
      ),
      (
        def encode(:PAYMENT_INVITE_SETUP_INVITEE_RECEIVE_ONLY) do
          179
        end

        def encode("PAYMENT_INVITE_SETUP_INVITEE_RECEIVE_ONLY") do
          179
        end
      ),
      (
        def encode(:PAYMENT_INVITE_SETUP_INVITEE_SEND_AND_RECEIVE) do
          180
        end

        def encode("PAYMENT_INVITE_SETUP_INVITEE_SEND_AND_RECEIVE") do
          180
        end
      ),
      (
        def encode(:LINKED_GROUP_CALL_START) do
          181
        end

        def encode("LINKED_GROUP_CALL_START") do
          181
        end
      ),
      (
        def encode(:REPORT_TO_ADMIN_ENABLED_STATUS) do
          182
        end

        def encode("REPORT_TO_ADMIN_ENABLED_STATUS") do
          182
        end
      ),
      (
        def encode(:EMPTY_SUBGROUP_CREATE) do
          183
        end

        def encode("EMPTY_SUBGROUP_CREATE") do
          183
        end
      ),
      (
        def encode(:SCHEDULED_CALL_CANCEL) do
          184
        end

        def encode("SCHEDULED_CALL_CANCEL") do
          184
        end
      ),
      (
        def encode(:SUBGROUP_ADMIN_TRIGGERED_AUTO_ADD_RICH) do
          185
        end

        def encode("SUBGROUP_ADMIN_TRIGGERED_AUTO_ADD_RICH") do
          185
        end
      ),
      (
        def encode(:GROUP_CHANGE_RECENT_HISTORY_SHARING) do
          186
        end

        def encode("GROUP_CHANGE_RECENT_HISTORY_SHARING") do
          186
        end
      ),
      (
        def encode(:PAID_MESSAGE_SERVER_CAMPAIGN_ID) do
          187
        end

        def encode("PAID_MESSAGE_SERVER_CAMPAIGN_ID") do
          187
        end
      ),
      (
        def encode(:GENERAL_CHAT_CREATE) do
          188
        end

        def encode("GENERAL_CHAT_CREATE") do
          188
        end
      ),
      (
        def encode(:GENERAL_CHAT_ADD) do
          189
        end

        def encode("GENERAL_CHAT_ADD") do
          189
        end
      ),
      (
        def encode(:GENERAL_CHAT_AUTO_ADD_DISABLED) do
          190
        end

        def encode("GENERAL_CHAT_AUTO_ADD_DISABLED") do
          190
        end
      ),
      (
        def encode(:SUGGESTED_SUBGROUP_ANNOUNCE) do
          191
        end

        def encode("SUGGESTED_SUBGROUP_ANNOUNCE") do
          191
        end
      ),
      (
        def encode(:BIZ_BOT_1P_MESSAGING_ENABLED) do
          192
        end

        def encode("BIZ_BOT_1P_MESSAGING_ENABLED") do
          192
        end
      ),
      (
        def encode(:CHANGE_USERNAME) do
          193
        end

        def encode("CHANGE_USERNAME") do
          193
        end
      ),
      (
        def encode(:BIZ_COEX_PRIVACY_INIT_SELF) do
          194
        end

        def encode("BIZ_COEX_PRIVACY_INIT_SELF") do
          194
        end
      ),
      (
        def encode(:BIZ_COEX_PRIVACY_TRANSITION_SELF) do
          195
        end

        def encode("BIZ_COEX_PRIVACY_TRANSITION_SELF") do
          195
        end
      ),
      (
        def encode(:SUPPORT_AI_EDUCATION) do
          196
        end

        def encode("SUPPORT_AI_EDUCATION") do
          196
        end
      ),
      (
        def encode(:BIZ_BOT_3P_MESSAGING_ENABLED) do
          197
        end

        def encode("BIZ_BOT_3P_MESSAGING_ENABLED") do
          197
        end
      ),
      (
        def encode(:REMINDER_SETUP_MESSAGE) do
          198
        end

        def encode("REMINDER_SETUP_MESSAGE") do
          198
        end
      ),
      (
        def encode(:REMINDER_SENT_MESSAGE) do
          199
        end

        def encode("REMINDER_SENT_MESSAGE") do
          199
        end
      ),
      (
        def encode(:REMINDER_CANCEL_MESSAGE) do
          200
        end

        def encode("REMINDER_CANCEL_MESSAGE") do
          200
        end
      ),
      (
        def encode(:BIZ_COEX_PRIVACY_INIT) do
          201
        end

        def encode("BIZ_COEX_PRIVACY_INIT") do
          201
        end
      ),
      (
        def encode(:BIZ_COEX_PRIVACY_TRANSITION) do
          202
        end

        def encode("BIZ_COEX_PRIVACY_TRANSITION") do
          202
        end
      ),
      (
        def encode(:GROUP_DEACTIVATED) do
          203
        end

        def encode("GROUP_DEACTIVATED") do
          203
        end
      ),
      (
        def encode(:COMMUNITY_DEACTIVATE_SIBLING_GROUP) do
          204
        end

        def encode("COMMUNITY_DEACTIVATE_SIBLING_GROUP") do
          204
        end
      ),
      (
        def encode(:EVENT_UPDATED) do
          205
        end

        def encode("EVENT_UPDATED") do
          205
        end
      ),
      (
        def encode(:EVENT_CANCELED) do
          206
        end

        def encode("EVENT_CANCELED") do
          206
        end
      ),
      (
        def encode(:COMMUNITY_OWNER_UPDATED) do
          207
        end

        def encode("COMMUNITY_OWNER_UPDATED") do
          207
        end
      ),
      (
        def encode(:COMMUNITY_SUB_GROUP_VISIBILITY_HIDDEN) do
          208
        end

        def encode("COMMUNITY_SUB_GROUP_VISIBILITY_HIDDEN") do
          208
        end
      ),
      (
        def encode(:CAPI_GROUP_NE2EE_SYSTEM_MESSAGE) do
          209
        end

        def encode("CAPI_GROUP_NE2EE_SYSTEM_MESSAGE") do
          209
        end
      ),
      (
        def encode(:STATUS_MENTION) do
          210
        end

        def encode("STATUS_MENTION") do
          210
        end
      ),
      (
        def encode(:USER_CONTROLS_SYSTEM_MESSAGE) do
          211
        end

        def encode("USER_CONTROLS_SYSTEM_MESSAGE") do
          211
        end
      ),
      (
        def encode(:SUPPORT_SYSTEM_MESSAGE) do
          212
        end

        def encode("SUPPORT_SYSTEM_MESSAGE") do
          212
        end
      ),
      (
        def encode(:CHANGE_LID) do
          213
        end

        def encode("CHANGE_LID") do
          213
        end
      ),
      (
        def encode(:BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_IN_MESSAGE) do
          214
        end

        def encode("BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_IN_MESSAGE") do
          214
        end
      ),
      (
        def encode(:BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_OUT_MESSAGE) do
          215
        end

        def encode("BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_OUT_MESSAGE") do
          215
        end
      ),
      (
        def encode(:CHANGE_LIMIT_SHARING) do
          216
        end

        def encode("CHANGE_LIMIT_SHARING") do
          216
        end
      ),
      (
        def encode(:GROUP_MEMBER_LINK_MODE) do
          217
        end

        def encode("GROUP_MEMBER_LINK_MODE") do
          217
        end
      ),
      (
        def encode(:BIZ_AUTOMATICALLY_LABELED_CHAT_SYSTEM_MESSAGE) do
          218
        end

        def encode("BIZ_AUTOMATICALLY_LABELED_CHAT_SYSTEM_MESSAGE") do
          218
        end
      ),
      (
        def encode(:PHONE_NUMBER_HIDING_CHAT_DEPRECATED_MESSAGE) do
          219
        end

        def encode("PHONE_NUMBER_HIDING_CHAT_DEPRECATED_MESSAGE") do
          219
        end
      ),
      (
        def encode(:QUARANTINED_MESSAGE) do
          220
        end

        def encode("QUARANTINED_MESSAGE") do
          220
        end
      ),
      (
        def encode(:GROUP_MEMBER_SHARE_GROUP_HISTORY_MODE) do
          221
        end

        def encode("GROUP_MEMBER_SHARE_GROUP_HISTORY_MODE") do
          221
        end
      ),
      (
        def encode(:GROUP_OPEN_BOT_ADDED) do
          222
        end

        def encode("GROUP_OPEN_BOT_ADDED") do
          222
        end
      ),
      (
        def encode(:GROUP_TEE_BOT_ADDED) do
          223
        end

        def encode("GROUP_TEE_BOT_ADDED") do
          223
        end
      ),
      (
        def encode(:CONTACT_INFO) do
          224
        end

        def encode("CONTACT_INFO") do
          224
        end
      ),
      (
        def encode(:SCHEDULED_MESSAGE_CREATED) do
          225
        end

        def encode("SCHEDULED_MESSAGE_CREATED") do
          225
        end
      ),
      (
        def encode(:IDENTITY_TRUST_MARKED) do
          226
        end

        def encode("IDENTITY_TRUST_MARKED") do
          226
        end
      ),
      (
        def encode(:IDENTITY_TRUST_UNMARKED) do
          227
        end

        def encode("IDENTITY_TRUST_UNMARKED") do
          227
        end
      ),
      (
        def encode(:IDENTITY_TRUST_REVOKED) do
          228
        end

        def encode("IDENTITY_TRUST_REVOKED") do
          228
        end
      ),
      (
        def encode(:CTWA_CONSUMER_DISCLOSURE) do
          230
        end

        def encode("CTWA_CONSUMER_DISCLOSURE") do
          230
        end
      )
    ]

    def encode(x) do
      x
    end

    @spec decode(integer()) :: atom() | integer()
    [
      def decode(54) do
        :PAYMENT_ACTION_ACCOUNT_SETUP_REMINDER
      end,
      def decode(18) do
        :VERIFIED_TRANSITION_NONE_TO_LOW
      end,
      def decode(169) do
        :SILENCED_UNKNOWN_CALLER_AUDIO
      end,
      def decode(96) do
        :BLUE_MSG_SELF_FB_VERIFIED
      end,
      def decode(94) do
        :BLUE_MSG_SELF_FB_UNVERIFIED
      end,
      def decode(84) do
        :BLUE_MSG_BSP_PREMISE_UNVERIFIED
      end,
      def decode(160) do
        :BIZ_CHAT_ASSIGNMENT_UNASSIGN
      end,
      def decode(4) do
        :NON_VERIFIED_TRANSITION
      end,
      def decode(136) do
        :COMMUNITY_LINK_SUB_GROUP
      end,
      def decode(72) do
        :CHANGE_EPHEMERAL_SETTING
      end,
      def decode(179) do
        :PAYMENT_INVITE_SETUP_INVITEE_RECEIVE_ONLY
      end,
      def decode(68) do
        :OVERSIZED
      end,
      def decode(93) do
        :BLUE_MSG_SELF_FB_TO_SELF_PREMISE
      end,
      def decode(34) do
        :BROADCAST_CREATE
      end,
      def decode(226) do
        :IDENTITY_TRUST_MARKED
      end,
      def decode(211) do
        :USER_CONTROLS_SYSTEM_MESSAGE
      end,
      def decode(128) do
        :BIZ_PRIVACY_MODE_TO_FB
      end,
      def decode(194) do
        :BIZ_COEX_PRIVACY_INIT_SELF
      end,
      def decode(46) do
        :CALL_MISSED_GROUP_VIDEO
      end,
      def decode(168) do
        :COMMUNITY_PARTICIPANT_ADD_RICH
      end,
      def decode(132) do
        :ADMIN_REVOKE
      end,
      def decode(207) do
        :COMMUNITY_OWNER_UPDATED
      end,
      def decode(52) do
        :PAYMENT_TRANSACTION_STATUS_RECEIVER_PENDING_SETUP
      end,
      def decode(150) do
        :COMMUNITY_LINK_PARENT_GROUP_MEMBERSHIP_APPROVAL
      end,
      def decode(154) do
        :BIZ_CHAT_ASSIGNMENT
      end,
      def decode(92) do
        :BLUE_MSG_SELF_FB_TO_BSP_PREMISE
      end,
      def decode(123) do
        :EPHEMERAL_SETTING_NOT_APPLIED
      end,
      def decode(156) do
        :CHAT_POLL_CREATION_MESSAGE
      end,
      def decode(12) do
        :VERIFIED_TRANSITION_ANY_TO_NONE
      end,
      def decode(182) do
        :REPORT_TO_ADMIN_ENABLED_STATUS
      end,
      def decode(19) do
        :VERIFIED_TRANSITION_NONE_TO_UNKNOWN
      end,
      def decode(213) do
        :CHANGE_LID
      end,
      def decode(110) do
        :BLUE_MSG_VERIFIED_TO_SELF_FB_UNVERIFIED
      end,
      def decode(91) do
        :BLUE_MSG_CONSUMER_TO_SELF_PREMISE_UNVERIFIED
      end,
      def decode(164) do
        :COMMUNITY_INVITE_AUTO_ADD_RICH
      end,
      def decode(139) do
        :COMMUNITY_UNLINK_SUB_GROUP
      end,
      def decode(212) do
        :SUPPORT_SYSTEM_MESSAGE
      end,
      def decode(41) do
        :CALL_MISSED_VIDEO
      end,
      def decode(114) do
        :BLUE_MSG_BSP_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED
      end,
      def decode(100) do
        :BLUE_MSG_SELF_PREMISE_VERIFIED
      end,
      def decode(29) do
        :GROUP_PARTICIPANT_PROMOTE
      end,
      def decode(171) do
        :GROUP_MEMBER_ADD_MODE
      end,
      def decode(140) do
        :GROUP_PARTICIPANT_ACCEPT
      end,
      def decode(13) do
        :VERIFIED_TRANSITION_ANY_TO_HIGH
      end,
      def decode(42) do
        :INDIVIDUAL_CHANGE_NUMBER
      end,
      def decode(149) do
        :COMMUNITY_PARENT_GROUP_DELETED
      end,
      def decode(55) do
        :PAYMENT_ACTION_SEND_PAYMENT_REMINDER
      end,
      def decode(2) do
        :CIPHERTEXT
      end,
      def decode(146) do
        :INTEGRITY_UNLINK_PARENT_GROUP
      end,
      def decode(191) do
        :SUGGESTED_SUBGROUP_ANNOUNCE
      end,
      def decode(202) do
        :BIZ_COEX_PRIVACY_TRANSITION
      end,
      def decode(192) do
        :BIZ_BOT_1P_MESSAGING_ENABLED
      end,
      def decode(98) do
        :BLUE_MSG_SELF_PREMISE_TO_BSP_PREMISE
      end,
      def decode(7) do
        :VERIFIED_LOW_UNKNOWN
      end,
      def decode(90) do
        :BLUE_MSG_CONSUMER_TO_SELF_FB_UNVERIFIED
      end,
      def decode(38) do
        :E2E_IDENTITY_CHANGED
      end,
      def decode(56) do
        :PAYMENT_ACTION_SEND_PAYMENT_INVITATION
      end,
      def decode(153) do
        :MASKED_THREAD_UNMASKED
      end,
      def decode(61) do
        :BIZ_VERIFIED_TRANSITION_BOTTOM_TO_TOP
      end,
      def decode(99) do
        :BLUE_MSG_SELF_PREMISE_UNVERIFIED
      end,
      def decode(113) do
        :BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_FB_VERIFIED
      end,
      def decode(201) do
        :BIZ_COEX_PRIVACY_INIT
      end,
      def decode(65) do
        :BIZ_MOVE_TO_CONSUMER_APP
      end,
      def decode(137) do
        :COMMUNITY_UNLINK_PARENT_GROUP
      end,
      def decode(141) do
        :GROUP_PARTICIPANT_LINKED_GROUP_JOIN
      end,
      def decode(230) do
        :CTWA_CONSUMER_DISCLOSURE
      end,
      def decode(104) do
        :BLUE_MSG_UNVERIFIED_TO_BSP_FB_VERIFIED
      end,
      def decode(187) do
        :PAID_MESSAGE_SERVER_CAMPAIGN_ID
      end,
      def decode(31) do
        :GROUP_PARTICIPANT_INVITE
      end,
      def decode(105) do
        :BLUE_MSG_UNVERIFIED_TO_BSP_PREMISE_VERIFIED
      end,
      def decode(115) do
        :BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_FB_UNVERIFIED
      end,
      def decode(172) do
        :GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST_NON_ADMIN_ADD
      end,
      def decode(134) do
        :COMMUNITY_LINK_PARENT_GROUP
      end,
      def decode(178) do
        :PAYMENT_INVITE_SETUP_INVITER
      end,
      def decode(204) do
        :COMMUNITY_DEACTIVATE_SIBLING_GROUP
      end,
      def decode(127) do
        :BIZ_PRIVACY_MODE_INIT_BSP
      end,
      def decode(176) do
        :COMMUNITY_ALLOW_MEMBER_ADDED_GROUPS
      end,
      def decode(147) do
        :COMMUNITY_PARTICIPANT_PROMOTE
      end,
      def decode(70) do
        :GROUP_V4_ADD_INVITE_SENT
      end,
      def decode(116) do
        :BLUE_MSG_SELF_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED
      end,
      def decode(8) do
        :VERIFIED_HIGH
      end,
      def decode(111) do
        :BLUE_MSG_VERIFIED_TO_UNVERIFIED
      end,
      def decode(143) do
        :EPHEMERAL_KEEP_IN_CHAT
      end,
      def decode(175) do
        :RECEIVER_INVITE
      end,
      def decode(181) do
        :LINKED_GROUP_CALL_START
      end,
      def decode(157) do
        :CAG_MASKED_THREAD_CREATED
      end,
      def decode(44) do
        :GROUP_ANNOUNCE_MODE_MESSAGE_BOUNCE
      end,
      def decode(10) do
        :VERIFIED_INITIAL_LOW
      end,
      def decode(101) do
        :BLUE_MSG_TO_BSP_FB
      end,
      def decode(23) do
        :GROUP_CHANGE_INVITE_LINK
      end,
      def decode(215) do
        :BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_OUT_MESSAGE
      end,
      def decode(220) do
        :QUARANTINED_MESSAGE
      end,
      def decode(112) do
        :BLUE_MSG_BSP_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED
      end,
      def decode(203) do
        :GROUP_DEACTIVATED
      end,
      def decode(9) do
        :VERIFIED_INITIAL_UNKNOWN
      end,
      def decode(82) do
        :BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED
      end,
      def decode(163) do
        :COMMUNITY_INVITE_RICH
      end,
      def decode(49) do
        :PAYMENT_TRANSACTION_STATUS_UPDATE_FAILED
      end,
      def decode(79) do
        :BLUE_MSG_BSP_FB_UNVERIFIED
      end,
      def decode(183) do
        :EMPTY_SUBGROUP_CREATE
      end,
      def decode(125) do
        :SYNCING
      end,
      def decode(209) do
        :CAPI_GROUP_NE2EE_SYSTEM_MESSAGE
      end,
      def decode(224) do
        :CONTACT_INFO
      end,
      def decode(103) do
        :BLUE_MSG_TO_SELF_FB
      end,
      def decode(198) do
        :REMINDER_SETUP_MESSAGE
      end,
      def decode(71) do
        :GROUP_PARTICIPANT_ADD_REQUEST_JOIN
      end,
      def decode(118) do
        :E2E_IDENTITY_UNAVAILABLE
      end,
      def decode(66) do
        :BIZ_TWO_TIER_MIGRATION_TOP
      end,
      def decode(109) do
        :BLUE_MSG_VERIFIED_TO_BSP_PREMISE_UNVERIFIED
      end,
      def decode(195) do
        :BIZ_COEX_PRIVACY_TRANSITION_SELF
      end,
      def decode(219) do
        :PHONE_NUMBER_HIDING_CHAT_DEPRECATED_MESSAGE
      end,
      def decode(75) do
        :E2E_ENCRYPTED_NOW
      end,
      def decode(131) do
        :E2E_DEVICE_FETCH_FAILED
      end,
      def decode(64) do
        :BIZ_NAME_CHANGE
      end,
      def decode(106) do
        :BLUE_MSG_UNVERIFIED_TO_SELF_FB_VERIFIED
      end,
      def decode(78) do
        :BLUE_MSG_BSP_FB_TO_SELF_PREMISE
      end,
      def decode(80) do
        :BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED
      end,
      def decode(15) do
        :VERIFIED_TRANSITION_HIGH_TO_UNKNOWN
      end,
      def decode(188) do
        :GENERAL_CHAT_CREATE
      end,
      def decode(117) do
        :BLUE_MSG_SELF_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED
      end,
      def decode(180) do
        :PAYMENT_INVITE_SETUP_INVITEE_SEND_AND_RECEIVE
      end,
      def decode(216) do
        :CHANGE_LIMIT_SHARING
      end,
      def decode(35) do
        :BROADCAST_ADD
      end,
      def decode(36) do
        :BROADCAST_REMOVE
      end,
      def decode(76) do
        :BLUE_MSG_BSP_FB_TO_BSP_PREMISE
      end,
      def decode(126) do
        :BIZ_PRIVACY_MODE_INIT_FB
      end,
      def decode(155) do
        :CHAT_PSA
      end,
      def decode(165) do
        :SUB_GROUP_INVITE_RICH
      end,
      def decode(228) do
        :IDENTITY_TRUST_REVOKED
      end,
      def decode(227) do
        :IDENTITY_TRUST_UNMARKED
      end,
      def decode(97) do
        :BLUE_MSG_SELF_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED
      end,
      def decode(32) do
        :GROUP_PARTICIPANT_LEAVE
      end,
      def decode(58) do
        :PAYMENT_ACTION_REQUEST_EXPIRED
      end,
      def decode(151) do
        :GROUP_PARTICIPANT_JOINED_GROUP_AND_PARENT_GROUP
      end,
      def decode(208) do
        :COMMUNITY_SUB_GROUP_VISIBILITY_HIDDEN
      end,
      def decode(197) do
        :BIZ_BOT_3P_MESSAGING_ENABLED
      end,
      def decode(133) do
        :GROUP_INVITE_LINK_GROWTH_LOCKED
      end,
      def decode(196) do
        :SUPPORT_AI_EDUCATION
      end,
      def decode(205) do
        :EVENT_UPDATED
      end,
      def decode(1) do
        :REVOKE
      end,
      def decode(177) do
        :PINNED_MESSAGE_IN_CHAT
      end,
      def decode(225) do
        :SCHEDULED_MESSAGE_CREATED
      end,
      def decode(25) do
        :GROUP_CHANGE_RESTRICT
      end,
      def decode(142) do
        :COMMUNITY_CREATE
      end,
      def decode(28) do
        :GROUP_PARTICIPANT_REMOVE
      end,
      def decode(223) do
        :GROUP_TEE_BOT_ADDED
      end,
      def decode(200) do
        :REMINDER_CANCEL_MESSAGE
      end,
      def decode(145) do
        :GROUP_MEMBERSHIP_JOIN_APPROVAL_MODE
      end,
      def decode(107) do
        :BLUE_MSG_UNVERIFIED_TO_VERIFIED
      end,
      def decode(60) do
        :BIZ_VERIFIED_TRANSITION_TOP_TO_BOTTOM
      end,
      def decode(108) do
        :BLUE_MSG_VERIFIED_TO_BSP_FB_UNVERIFIED
      end,
      def decode(20) do
        :GROUP_CREATE
      end,
      def decode(87) do
        :BLUE_MSG_BSP_PREMISE_VERIFIED_TO_SELF_PREMISE_UNVERIFIED
      end,
      def decode(184) do
        :SCHEDULED_CALL_CANCEL
      end,
      def decode(6) do
        :VERIFIED_TRANSITION
      end,
      def decode(214) do
        :BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_IN_MESSAGE
      end,
      def decode(199) do
        :REMINDER_SENT_MESSAGE
      end,
      def decode(144) do
        :GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST
      end,
      def decode(95) do
        :BLUE_MSG_SELF_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED
      end,
      def decode(174) do
        :SENDER_INVITE
      end,
      def decode(193) do
        :CHANGE_USERNAME
      end,
      def decode(138) do
        :COMMUNITY_UNLINK_SIBLING_GROUP
      end,
      def decode(186) do
        :GROUP_CHANGE_RECENT_HISTORY_SHARING
      end,
      def decode(83) do
        :BLUE_MSG_BSP_PREMISE_TO_SELF_PREMISE
      end,
      def decode(43) do
        :GROUP_DELETE
      end,
      def decode(158) do
        :COMMUNITY_PARENT_GROUP_SUBJECT_CHANGED
      end,
      def decode(57) do
        :PAYMENT_ACTION_REQUEST_DECLINED
      end,
      def decode(11) do
        :VERIFIED_INITIAL_HIGH
      end,
      def decode(81) do
        :BLUE_MSG_BSP_FB_VERIFIED
      end,
      def decode(161) do
        :CAG_INVITE_AUTO_JOINED
      end,
      def decode(119) do
        :GROUP_CREATING
      end,
      def decode(148) do
        :COMMUNITY_PARTICIPANT_DEMOTE
      end,
      def decode(167) do
        :COMMUNITY_LINK_PARENT_GROUP_RICH
      end,
      def decode(73) do
        :E2E_DEVICE_CHANGED
      end,
      def decode(89) do
        :BLUE_MSG_CONSUMER_TO_BSP_PREMISE_UNVERIFIED
      end,
      def decode(88) do
        :BLUE_MSG_CONSUMER_TO_BSP_FB_UNVERIFIED
      end,
      def decode(48) do
        :PAYMENT_FUTUREPROOF
      end,
      def decode(17) do
        :VERIFIED_TRANSITION_LOW_TO_UNKNOWN
      end,
      def decode(24) do
        :GROUP_CHANGE_DESCRIPTION
      end,
      def decode(37) do
        :GENERIC_NOTIFICATION
      end,
      def decode(40) do
        :CALL_MISSED_VOICE
      end,
      def decode(14) do
        :VERIFIED_TRANSITION_HIGH_TO_LOW
      end,
      def decode(210) do
        :STATUS_MENTION
      end,
      def decode(162) do
        :SCHEDULED_CALL_START_MESSAGE
      end,
      def decode(190) do
        :GENERAL_CHAT_AUTO_ADD_DISABLED
      end,
      def decode(33) do
        :GROUP_PARTICIPANT_CHANGE_NUMBER
      end,
      def decode(53) do
        :PAYMENT_TRANSACTION_STATUS_RECEIVER_SUCCESS_AFTER_HICCUP
      end,
      def decode(159) do
        :CAG_INVITE_AUTO_ADD
      end,
      def decode(206) do
        :EVENT_CANCELED
      end,
      def decode(3) do
        :FUTUREPROOF
      end,
      def decode(16) do
        :VERIFIED_TRANSITION_UNKNOWN_TO_LOW
      end,
      def decode(30) do
        :GROUP_PARTICIPANT_DEMOTE
      end,
      def decode(62) do
        :BIZ_INTRO_TOP
      end,
      def decode(173) do
        :COMMUNITY_CHANGE_DESCRIPTION
      end,
      def decode(185) do
        :SUBGROUP_ADMIN_TRIGGERED_AUTO_ADD_RICH
      end,
      def decode(86) do
        :BLUE_MSG_BSP_PREMISE_VERIFIED
      end,
      def decode(21) do
        :GROUP_CHANGE_SUBJECT
      end,
      def decode(5) do
        :UNVERIFIED_TRANSITION
      end,
      def decode(122) do
        :BLOCK_CONTACT
      end,
      def decode(0) do
        :UNKNOWN
      end,
      def decode(77) do
        :BLUE_MSG_BSP_FB_TO_SELF_FB
      end,
      def decode(27) do
        :GROUP_PARTICIPANT_ADD
      end,
      def decode(85) do
        :BLUE_MSG_BSP_PREMISE_UNVERIFIED_TO_SELF_PREMISE_VERIFIED
      end,
      def decode(47) do
        :PAYMENT_CIPHERTEXT
      end,
      def decode(63) do
        :BIZ_INTRO_BOTTOM
      end,
      def decode(129) do
        :BIZ_PRIVACY_MODE_TO_BSP
      end,
      def decode(124) do
        :SYNC_FAILED
      end,
      def decode(26) do
        :GROUP_CHANGE_ANNOUNCE
      end,
      def decode(51) do
        :PAYMENT_TRANSACTION_STATUS_UPDATE_REFUND_FAILED
      end,
      def decode(217) do
        :GROUP_MEMBER_LINK_MODE
      end,
      def decode(121) do
        :GROUP_BOUNCED
      end,
      def decode(102) do
        :BLUE_MSG_TO_CONSUMER
      end,
      def decode(22) do
        :GROUP_CHANGE_ICON
      end,
      def decode(50) do
        :PAYMENT_TRANSACTION_STATUS_UPDATE_REFUNDED
      end,
      def decode(221) do
        :GROUP_MEMBER_SHARE_GROUP_HISTORY_MODE
      end,
      def decode(45) do
        :CALL_MISSED_GROUP_VOICE
      end,
      def decode(189) do
        :GENERAL_CHAT_ADD
      end,
      def decode(120) do
        :GROUP_CREATE_FAILED
      end,
      def decode(170) do
        :SILENCED_UNKNOWN_CALLER_VIDEO
      end,
      def decode(67) do
        :BIZ_TWO_TIER_MIGRATION_BOTTOM
      end,
      def decode(152) do
        :MASKED_THREAD_CREATED
      end,
      def decode(69) do
        :GROUP_CHANGE_NO_FREQUENTLY_FORWARDED
      end,
      def decode(59) do
        :PAYMENT_ACTION_REQUEST_CANCELLED
      end,
      def decode(218) do
        :BIZ_AUTOMATICALLY_LABELED_CHAT_SYSTEM_MESSAGE
      end,
      def decode(135) do
        :COMMUNITY_LINK_SIBLING_GROUP
      end,
      def decode(74) do
        :VIEWED_ONCE
      end,
      def decode(222) do
        :GROUP_OPEN_BOT_ADDED
      end,
      def decode(130) do
        :DISAPPEARING_MODE
      end,
      def decode(39) do
        :E2E_ENCRYPTED
      end,
      def decode(166) do
        :SUB_GROUP_PARTICIPANT_ADD_RICH
      end
    ]

    def decode(x) do
      x
    end

    @spec constants() :: [{integer(), atom()}]
    def constants() do
      [
        {0, :UNKNOWN},
        {1, :REVOKE},
        {2, :CIPHERTEXT},
        {3, :FUTUREPROOF},
        {4, :NON_VERIFIED_TRANSITION},
        {5, :UNVERIFIED_TRANSITION},
        {6, :VERIFIED_TRANSITION},
        {7, :VERIFIED_LOW_UNKNOWN},
        {8, :VERIFIED_HIGH},
        {9, :VERIFIED_INITIAL_UNKNOWN},
        {10, :VERIFIED_INITIAL_LOW},
        {11, :VERIFIED_INITIAL_HIGH},
        {12, :VERIFIED_TRANSITION_ANY_TO_NONE},
        {13, :VERIFIED_TRANSITION_ANY_TO_HIGH},
        {14, :VERIFIED_TRANSITION_HIGH_TO_LOW},
        {15, :VERIFIED_TRANSITION_HIGH_TO_UNKNOWN},
        {16, :VERIFIED_TRANSITION_UNKNOWN_TO_LOW},
        {17, :VERIFIED_TRANSITION_LOW_TO_UNKNOWN},
        {18, :VERIFIED_TRANSITION_NONE_TO_LOW},
        {19, :VERIFIED_TRANSITION_NONE_TO_UNKNOWN},
        {20, :GROUP_CREATE},
        {21, :GROUP_CHANGE_SUBJECT},
        {22, :GROUP_CHANGE_ICON},
        {23, :GROUP_CHANGE_INVITE_LINK},
        {24, :GROUP_CHANGE_DESCRIPTION},
        {25, :GROUP_CHANGE_RESTRICT},
        {26, :GROUP_CHANGE_ANNOUNCE},
        {27, :GROUP_PARTICIPANT_ADD},
        {28, :GROUP_PARTICIPANT_REMOVE},
        {29, :GROUP_PARTICIPANT_PROMOTE},
        {30, :GROUP_PARTICIPANT_DEMOTE},
        {31, :GROUP_PARTICIPANT_INVITE},
        {32, :GROUP_PARTICIPANT_LEAVE},
        {33, :GROUP_PARTICIPANT_CHANGE_NUMBER},
        {34, :BROADCAST_CREATE},
        {35, :BROADCAST_ADD},
        {36, :BROADCAST_REMOVE},
        {37, :GENERIC_NOTIFICATION},
        {38, :E2E_IDENTITY_CHANGED},
        {39, :E2E_ENCRYPTED},
        {40, :CALL_MISSED_VOICE},
        {41, :CALL_MISSED_VIDEO},
        {42, :INDIVIDUAL_CHANGE_NUMBER},
        {43, :GROUP_DELETE},
        {44, :GROUP_ANNOUNCE_MODE_MESSAGE_BOUNCE},
        {45, :CALL_MISSED_GROUP_VOICE},
        {46, :CALL_MISSED_GROUP_VIDEO},
        {47, :PAYMENT_CIPHERTEXT},
        {48, :PAYMENT_FUTUREPROOF},
        {49, :PAYMENT_TRANSACTION_STATUS_UPDATE_FAILED},
        {50, :PAYMENT_TRANSACTION_STATUS_UPDATE_REFUNDED},
        {51, :PAYMENT_TRANSACTION_STATUS_UPDATE_REFUND_FAILED},
        {52, :PAYMENT_TRANSACTION_STATUS_RECEIVER_PENDING_SETUP},
        {53, :PAYMENT_TRANSACTION_STATUS_RECEIVER_SUCCESS_AFTER_HICCUP},
        {54, :PAYMENT_ACTION_ACCOUNT_SETUP_REMINDER},
        {55, :PAYMENT_ACTION_SEND_PAYMENT_REMINDER},
        {56, :PAYMENT_ACTION_SEND_PAYMENT_INVITATION},
        {57, :PAYMENT_ACTION_REQUEST_DECLINED},
        {58, :PAYMENT_ACTION_REQUEST_EXPIRED},
        {59, :PAYMENT_ACTION_REQUEST_CANCELLED},
        {60, :BIZ_VERIFIED_TRANSITION_TOP_TO_BOTTOM},
        {61, :BIZ_VERIFIED_TRANSITION_BOTTOM_TO_TOP},
        {62, :BIZ_INTRO_TOP},
        {63, :BIZ_INTRO_BOTTOM},
        {64, :BIZ_NAME_CHANGE},
        {65, :BIZ_MOVE_TO_CONSUMER_APP},
        {66, :BIZ_TWO_TIER_MIGRATION_TOP},
        {67, :BIZ_TWO_TIER_MIGRATION_BOTTOM},
        {68, :OVERSIZED},
        {69, :GROUP_CHANGE_NO_FREQUENTLY_FORWARDED},
        {70, :GROUP_V4_ADD_INVITE_SENT},
        {71, :GROUP_PARTICIPANT_ADD_REQUEST_JOIN},
        {72, :CHANGE_EPHEMERAL_SETTING},
        {73, :E2E_DEVICE_CHANGED},
        {74, :VIEWED_ONCE},
        {75, :E2E_ENCRYPTED_NOW},
        {76, :BLUE_MSG_BSP_FB_TO_BSP_PREMISE},
        {77, :BLUE_MSG_BSP_FB_TO_SELF_FB},
        {78, :BLUE_MSG_BSP_FB_TO_SELF_PREMISE},
        {79, :BLUE_MSG_BSP_FB_UNVERIFIED},
        {80, :BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED},
        {81, :BLUE_MSG_BSP_FB_VERIFIED},
        {82, :BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED},
        {83, :BLUE_MSG_BSP_PREMISE_TO_SELF_PREMISE},
        {84, :BLUE_MSG_BSP_PREMISE_UNVERIFIED},
        {85, :BLUE_MSG_BSP_PREMISE_UNVERIFIED_TO_SELF_PREMISE_VERIFIED},
        {86, :BLUE_MSG_BSP_PREMISE_VERIFIED},
        {87, :BLUE_MSG_BSP_PREMISE_VERIFIED_TO_SELF_PREMISE_UNVERIFIED},
        {88, :BLUE_MSG_CONSUMER_TO_BSP_FB_UNVERIFIED},
        {89, :BLUE_MSG_CONSUMER_TO_BSP_PREMISE_UNVERIFIED},
        {90, :BLUE_MSG_CONSUMER_TO_SELF_FB_UNVERIFIED},
        {91, :BLUE_MSG_CONSUMER_TO_SELF_PREMISE_UNVERIFIED},
        {92, :BLUE_MSG_SELF_FB_TO_BSP_PREMISE},
        {93, :BLUE_MSG_SELF_FB_TO_SELF_PREMISE},
        {94, :BLUE_MSG_SELF_FB_UNVERIFIED},
        {95, :BLUE_MSG_SELF_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED},
        {96, :BLUE_MSG_SELF_FB_VERIFIED},
        {97, :BLUE_MSG_SELF_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED},
        {98, :BLUE_MSG_SELF_PREMISE_TO_BSP_PREMISE},
        {99, :BLUE_MSG_SELF_PREMISE_UNVERIFIED},
        {100, :BLUE_MSG_SELF_PREMISE_VERIFIED},
        {101, :BLUE_MSG_TO_BSP_FB},
        {102, :BLUE_MSG_TO_CONSUMER},
        {103, :BLUE_MSG_TO_SELF_FB},
        {104, :BLUE_MSG_UNVERIFIED_TO_BSP_FB_VERIFIED},
        {105, :BLUE_MSG_UNVERIFIED_TO_BSP_PREMISE_VERIFIED},
        {106, :BLUE_MSG_UNVERIFIED_TO_SELF_FB_VERIFIED},
        {107, :BLUE_MSG_UNVERIFIED_TO_VERIFIED},
        {108, :BLUE_MSG_VERIFIED_TO_BSP_FB_UNVERIFIED},
        {109, :BLUE_MSG_VERIFIED_TO_BSP_PREMISE_UNVERIFIED},
        {110, :BLUE_MSG_VERIFIED_TO_SELF_FB_UNVERIFIED},
        {111, :BLUE_MSG_VERIFIED_TO_UNVERIFIED},
        {112, :BLUE_MSG_BSP_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED},
        {113, :BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_FB_VERIFIED},
        {114, :BLUE_MSG_BSP_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED},
        {115, :BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_FB_UNVERIFIED},
        {116, :BLUE_MSG_SELF_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED},
        {117, :BLUE_MSG_SELF_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED},
        {118, :E2E_IDENTITY_UNAVAILABLE},
        {119, :GROUP_CREATING},
        {120, :GROUP_CREATE_FAILED},
        {121, :GROUP_BOUNCED},
        {122, :BLOCK_CONTACT},
        {123, :EPHEMERAL_SETTING_NOT_APPLIED},
        {124, :SYNC_FAILED},
        {125, :SYNCING},
        {126, :BIZ_PRIVACY_MODE_INIT_FB},
        {127, :BIZ_PRIVACY_MODE_INIT_BSP},
        {128, :BIZ_PRIVACY_MODE_TO_FB},
        {129, :BIZ_PRIVACY_MODE_TO_BSP},
        {130, :DISAPPEARING_MODE},
        {131, :E2E_DEVICE_FETCH_FAILED},
        {132, :ADMIN_REVOKE},
        {133, :GROUP_INVITE_LINK_GROWTH_LOCKED},
        {134, :COMMUNITY_LINK_PARENT_GROUP},
        {135, :COMMUNITY_LINK_SIBLING_GROUP},
        {136, :COMMUNITY_LINK_SUB_GROUP},
        {137, :COMMUNITY_UNLINK_PARENT_GROUP},
        {138, :COMMUNITY_UNLINK_SIBLING_GROUP},
        {139, :COMMUNITY_UNLINK_SUB_GROUP},
        {140, :GROUP_PARTICIPANT_ACCEPT},
        {141, :GROUP_PARTICIPANT_LINKED_GROUP_JOIN},
        {142, :COMMUNITY_CREATE},
        {143, :EPHEMERAL_KEEP_IN_CHAT},
        {144, :GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST},
        {145, :GROUP_MEMBERSHIP_JOIN_APPROVAL_MODE},
        {146, :INTEGRITY_UNLINK_PARENT_GROUP},
        {147, :COMMUNITY_PARTICIPANT_PROMOTE},
        {148, :COMMUNITY_PARTICIPANT_DEMOTE},
        {149, :COMMUNITY_PARENT_GROUP_DELETED},
        {150, :COMMUNITY_LINK_PARENT_GROUP_MEMBERSHIP_APPROVAL},
        {151, :GROUP_PARTICIPANT_JOINED_GROUP_AND_PARENT_GROUP},
        {152, :MASKED_THREAD_CREATED},
        {153, :MASKED_THREAD_UNMASKED},
        {154, :BIZ_CHAT_ASSIGNMENT},
        {155, :CHAT_PSA},
        {156, :CHAT_POLL_CREATION_MESSAGE},
        {157, :CAG_MASKED_THREAD_CREATED},
        {158, :COMMUNITY_PARENT_GROUP_SUBJECT_CHANGED},
        {159, :CAG_INVITE_AUTO_ADD},
        {160, :BIZ_CHAT_ASSIGNMENT_UNASSIGN},
        {161, :CAG_INVITE_AUTO_JOINED},
        {162, :SCHEDULED_CALL_START_MESSAGE},
        {163, :COMMUNITY_INVITE_RICH},
        {164, :COMMUNITY_INVITE_AUTO_ADD_RICH},
        {165, :SUB_GROUP_INVITE_RICH},
        {166, :SUB_GROUP_PARTICIPANT_ADD_RICH},
        {167, :COMMUNITY_LINK_PARENT_GROUP_RICH},
        {168, :COMMUNITY_PARTICIPANT_ADD_RICH},
        {169, :SILENCED_UNKNOWN_CALLER_AUDIO},
        {170, :SILENCED_UNKNOWN_CALLER_VIDEO},
        {171, :GROUP_MEMBER_ADD_MODE},
        {172, :GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST_NON_ADMIN_ADD},
        {173, :COMMUNITY_CHANGE_DESCRIPTION},
        {174, :SENDER_INVITE},
        {175, :RECEIVER_INVITE},
        {176, :COMMUNITY_ALLOW_MEMBER_ADDED_GROUPS},
        {177, :PINNED_MESSAGE_IN_CHAT},
        {178, :PAYMENT_INVITE_SETUP_INVITER},
        {179, :PAYMENT_INVITE_SETUP_INVITEE_RECEIVE_ONLY},
        {180, :PAYMENT_INVITE_SETUP_INVITEE_SEND_AND_RECEIVE},
        {181, :LINKED_GROUP_CALL_START},
        {182, :REPORT_TO_ADMIN_ENABLED_STATUS},
        {183, :EMPTY_SUBGROUP_CREATE},
        {184, :SCHEDULED_CALL_CANCEL},
        {185, :SUBGROUP_ADMIN_TRIGGERED_AUTO_ADD_RICH},
        {186, :GROUP_CHANGE_RECENT_HISTORY_SHARING},
        {187, :PAID_MESSAGE_SERVER_CAMPAIGN_ID},
        {188, :GENERAL_CHAT_CREATE},
        {189, :GENERAL_CHAT_ADD},
        {190, :GENERAL_CHAT_AUTO_ADD_DISABLED},
        {191, :SUGGESTED_SUBGROUP_ANNOUNCE},
        {192, :BIZ_BOT_1P_MESSAGING_ENABLED},
        {193, :CHANGE_USERNAME},
        {194, :BIZ_COEX_PRIVACY_INIT_SELF},
        {195, :BIZ_COEX_PRIVACY_TRANSITION_SELF},
        {196, :SUPPORT_AI_EDUCATION},
        {197, :BIZ_BOT_3P_MESSAGING_ENABLED},
        {198, :REMINDER_SETUP_MESSAGE},
        {199, :REMINDER_SENT_MESSAGE},
        {200, :REMINDER_CANCEL_MESSAGE},
        {201, :BIZ_COEX_PRIVACY_INIT},
        {202, :BIZ_COEX_PRIVACY_TRANSITION},
        {203, :GROUP_DEACTIVATED},
        {204, :COMMUNITY_DEACTIVATE_SIBLING_GROUP},
        {205, :EVENT_UPDATED},
        {206, :EVENT_CANCELED},
        {207, :COMMUNITY_OWNER_UPDATED},
        {208, :COMMUNITY_SUB_GROUP_VISIBILITY_HIDDEN},
        {209, :CAPI_GROUP_NE2EE_SYSTEM_MESSAGE},
        {210, :STATUS_MENTION},
        {211, :USER_CONTROLS_SYSTEM_MESSAGE},
        {212, :SUPPORT_SYSTEM_MESSAGE},
        {213, :CHANGE_LID},
        {214, :BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_IN_MESSAGE},
        {215, :BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_OUT_MESSAGE},
        {216, :CHANGE_LIMIT_SHARING},
        {217, :GROUP_MEMBER_LINK_MODE},
        {218, :BIZ_AUTOMATICALLY_LABELED_CHAT_SYSTEM_MESSAGE},
        {219, :PHONE_NUMBER_HIDING_CHAT_DEPRECATED_MESSAGE},
        {220, :QUARANTINED_MESSAGE},
        {221, :GROUP_MEMBER_SHARE_GROUP_HISTORY_MODE},
        {222, :GROUP_OPEN_BOT_ADDED},
        {223, :GROUP_TEE_BOT_ADDED},
        {224, :CONTACT_INFO},
        {225, :SCHEDULED_MESSAGE_CREATED},
        {226, :IDENTITY_TRUST_MARKED},
        {227, :IDENTITY_TRUST_UNMARKED},
        {228, :IDENTITY_TRUST_REVOKED},
        {230, :CTWA_CONSUMER_DISCLOSURE}
      ]
    end

    @spec has_constant?(any()) :: boolean()
    (
      [
        def has_constant?(:UNKNOWN) do
          true
        end,
        def has_constant?(:REVOKE) do
          true
        end,
        def has_constant?(:CIPHERTEXT) do
          true
        end,
        def has_constant?(:FUTUREPROOF) do
          true
        end,
        def has_constant?(:NON_VERIFIED_TRANSITION) do
          true
        end,
        def has_constant?(:UNVERIFIED_TRANSITION) do
          true
        end,
        def has_constant?(:VERIFIED_TRANSITION) do
          true
        end,
        def has_constant?(:VERIFIED_LOW_UNKNOWN) do
          true
        end,
        def has_constant?(:VERIFIED_HIGH) do
          true
        end,
        def has_constant?(:VERIFIED_INITIAL_UNKNOWN) do
          true
        end,
        def has_constant?(:VERIFIED_INITIAL_LOW) do
          true
        end,
        def has_constant?(:VERIFIED_INITIAL_HIGH) do
          true
        end,
        def has_constant?(:VERIFIED_TRANSITION_ANY_TO_NONE) do
          true
        end,
        def has_constant?(:VERIFIED_TRANSITION_ANY_TO_HIGH) do
          true
        end,
        def has_constant?(:VERIFIED_TRANSITION_HIGH_TO_LOW) do
          true
        end,
        def has_constant?(:VERIFIED_TRANSITION_HIGH_TO_UNKNOWN) do
          true
        end,
        def has_constant?(:VERIFIED_TRANSITION_UNKNOWN_TO_LOW) do
          true
        end,
        def has_constant?(:VERIFIED_TRANSITION_LOW_TO_UNKNOWN) do
          true
        end,
        def has_constant?(:VERIFIED_TRANSITION_NONE_TO_LOW) do
          true
        end,
        def has_constant?(:VERIFIED_TRANSITION_NONE_TO_UNKNOWN) do
          true
        end,
        def has_constant?(:GROUP_CREATE) do
          true
        end,
        def has_constant?(:GROUP_CHANGE_SUBJECT) do
          true
        end,
        def has_constant?(:GROUP_CHANGE_ICON) do
          true
        end,
        def has_constant?(:GROUP_CHANGE_INVITE_LINK) do
          true
        end,
        def has_constant?(:GROUP_CHANGE_DESCRIPTION) do
          true
        end,
        def has_constant?(:GROUP_CHANGE_RESTRICT) do
          true
        end,
        def has_constant?(:GROUP_CHANGE_ANNOUNCE) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_ADD) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_REMOVE) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_PROMOTE) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_DEMOTE) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_INVITE) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_LEAVE) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_CHANGE_NUMBER) do
          true
        end,
        def has_constant?(:BROADCAST_CREATE) do
          true
        end,
        def has_constant?(:BROADCAST_ADD) do
          true
        end,
        def has_constant?(:BROADCAST_REMOVE) do
          true
        end,
        def has_constant?(:GENERIC_NOTIFICATION) do
          true
        end,
        def has_constant?(:E2E_IDENTITY_CHANGED) do
          true
        end,
        def has_constant?(:E2E_ENCRYPTED) do
          true
        end,
        def has_constant?(:CALL_MISSED_VOICE) do
          true
        end,
        def has_constant?(:CALL_MISSED_VIDEO) do
          true
        end,
        def has_constant?(:INDIVIDUAL_CHANGE_NUMBER) do
          true
        end,
        def has_constant?(:GROUP_DELETE) do
          true
        end,
        def has_constant?(:GROUP_ANNOUNCE_MODE_MESSAGE_BOUNCE) do
          true
        end,
        def has_constant?(:CALL_MISSED_GROUP_VOICE) do
          true
        end,
        def has_constant?(:CALL_MISSED_GROUP_VIDEO) do
          true
        end,
        def has_constant?(:PAYMENT_CIPHERTEXT) do
          true
        end,
        def has_constant?(:PAYMENT_FUTUREPROOF) do
          true
        end,
        def has_constant?(:PAYMENT_TRANSACTION_STATUS_UPDATE_FAILED) do
          true
        end,
        def has_constant?(:PAYMENT_TRANSACTION_STATUS_UPDATE_REFUNDED) do
          true
        end,
        def has_constant?(:PAYMENT_TRANSACTION_STATUS_UPDATE_REFUND_FAILED) do
          true
        end,
        def has_constant?(:PAYMENT_TRANSACTION_STATUS_RECEIVER_PENDING_SETUP) do
          true
        end,
        def has_constant?(:PAYMENT_TRANSACTION_STATUS_RECEIVER_SUCCESS_AFTER_HICCUP) do
          true
        end,
        def has_constant?(:PAYMENT_ACTION_ACCOUNT_SETUP_REMINDER) do
          true
        end,
        def has_constant?(:PAYMENT_ACTION_SEND_PAYMENT_REMINDER) do
          true
        end,
        def has_constant?(:PAYMENT_ACTION_SEND_PAYMENT_INVITATION) do
          true
        end,
        def has_constant?(:PAYMENT_ACTION_REQUEST_DECLINED) do
          true
        end,
        def has_constant?(:PAYMENT_ACTION_REQUEST_EXPIRED) do
          true
        end,
        def has_constant?(:PAYMENT_ACTION_REQUEST_CANCELLED) do
          true
        end,
        def has_constant?(:BIZ_VERIFIED_TRANSITION_TOP_TO_BOTTOM) do
          true
        end,
        def has_constant?(:BIZ_VERIFIED_TRANSITION_BOTTOM_TO_TOP) do
          true
        end,
        def has_constant?(:BIZ_INTRO_TOP) do
          true
        end,
        def has_constant?(:BIZ_INTRO_BOTTOM) do
          true
        end,
        def has_constant?(:BIZ_NAME_CHANGE) do
          true
        end,
        def has_constant?(:BIZ_MOVE_TO_CONSUMER_APP) do
          true
        end,
        def has_constant?(:BIZ_TWO_TIER_MIGRATION_TOP) do
          true
        end,
        def has_constant?(:BIZ_TWO_TIER_MIGRATION_BOTTOM) do
          true
        end,
        def has_constant?(:OVERSIZED) do
          true
        end,
        def has_constant?(:GROUP_CHANGE_NO_FREQUENTLY_FORWARDED) do
          true
        end,
        def has_constant?(:GROUP_V4_ADD_INVITE_SENT) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_ADD_REQUEST_JOIN) do
          true
        end,
        def has_constant?(:CHANGE_EPHEMERAL_SETTING) do
          true
        end,
        def has_constant?(:E2E_DEVICE_CHANGED) do
          true
        end,
        def has_constant?(:VIEWED_ONCE) do
          true
        end,
        def has_constant?(:E2E_ENCRYPTED_NOW) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_TO_BSP_PREMISE) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_TO_SELF_FB) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_TO_SELF_PREMISE) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_PREMISE_TO_SELF_PREMISE) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_PREMISE_UNVERIFIED_TO_SELF_PREMISE_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_PREMISE_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_PREMISE_VERIFIED_TO_SELF_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_CONSUMER_TO_BSP_FB_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_CONSUMER_TO_BSP_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_CONSUMER_TO_SELF_FB_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_CONSUMER_TO_SELF_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_FB_TO_BSP_PREMISE) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_FB_TO_SELF_PREMISE) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_FB_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_FB_UNVERIFIED_TO_SELF_PREMISE_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_FB_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_FB_VERIFIED_TO_SELF_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_PREMISE_TO_BSP_PREMISE) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_PREMISE_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_TO_BSP_FB) do
          true
        end,
        def has_constant?(:BLUE_MSG_TO_CONSUMER) do
          true
        end,
        def has_constant?(:BLUE_MSG_TO_SELF_FB) do
          true
        end,
        def has_constant?(:BLUE_MSG_UNVERIFIED_TO_BSP_FB_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_UNVERIFIED_TO_BSP_PREMISE_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_UNVERIFIED_TO_SELF_FB_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_UNVERIFIED_TO_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_VERIFIED_TO_BSP_FB_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_VERIFIED_TO_BSP_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_VERIFIED_TO_SELF_FB_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_VERIFIED_TO_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_UNVERIFIED_TO_SELF_FB_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_BSP_FB_VERIFIED_TO_SELF_FB_UNVERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_FB_UNVERIFIED_TO_BSP_PREMISE_VERIFIED) do
          true
        end,
        def has_constant?(:BLUE_MSG_SELF_FB_VERIFIED_TO_BSP_PREMISE_UNVERIFIED) do
          true
        end,
        def has_constant?(:E2E_IDENTITY_UNAVAILABLE) do
          true
        end,
        def has_constant?(:GROUP_CREATING) do
          true
        end,
        def has_constant?(:GROUP_CREATE_FAILED) do
          true
        end,
        def has_constant?(:GROUP_BOUNCED) do
          true
        end,
        def has_constant?(:BLOCK_CONTACT) do
          true
        end,
        def has_constant?(:EPHEMERAL_SETTING_NOT_APPLIED) do
          true
        end,
        def has_constant?(:SYNC_FAILED) do
          true
        end,
        def has_constant?(:SYNCING) do
          true
        end,
        def has_constant?(:BIZ_PRIVACY_MODE_INIT_FB) do
          true
        end,
        def has_constant?(:BIZ_PRIVACY_MODE_INIT_BSP) do
          true
        end,
        def has_constant?(:BIZ_PRIVACY_MODE_TO_FB) do
          true
        end,
        def has_constant?(:BIZ_PRIVACY_MODE_TO_BSP) do
          true
        end,
        def has_constant?(:DISAPPEARING_MODE) do
          true
        end,
        def has_constant?(:E2E_DEVICE_FETCH_FAILED) do
          true
        end,
        def has_constant?(:ADMIN_REVOKE) do
          true
        end,
        def has_constant?(:GROUP_INVITE_LINK_GROWTH_LOCKED) do
          true
        end,
        def has_constant?(:COMMUNITY_LINK_PARENT_GROUP) do
          true
        end,
        def has_constant?(:COMMUNITY_LINK_SIBLING_GROUP) do
          true
        end,
        def has_constant?(:COMMUNITY_LINK_SUB_GROUP) do
          true
        end,
        def has_constant?(:COMMUNITY_UNLINK_PARENT_GROUP) do
          true
        end,
        def has_constant?(:COMMUNITY_UNLINK_SIBLING_GROUP) do
          true
        end,
        def has_constant?(:COMMUNITY_UNLINK_SUB_GROUP) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_ACCEPT) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_LINKED_GROUP_JOIN) do
          true
        end,
        def has_constant?(:COMMUNITY_CREATE) do
          true
        end,
        def has_constant?(:EPHEMERAL_KEEP_IN_CHAT) do
          true
        end,
        def has_constant?(:GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST) do
          true
        end,
        def has_constant?(:GROUP_MEMBERSHIP_JOIN_APPROVAL_MODE) do
          true
        end,
        def has_constant?(:INTEGRITY_UNLINK_PARENT_GROUP) do
          true
        end,
        def has_constant?(:COMMUNITY_PARTICIPANT_PROMOTE) do
          true
        end,
        def has_constant?(:COMMUNITY_PARTICIPANT_DEMOTE) do
          true
        end,
        def has_constant?(:COMMUNITY_PARENT_GROUP_DELETED) do
          true
        end,
        def has_constant?(:COMMUNITY_LINK_PARENT_GROUP_MEMBERSHIP_APPROVAL) do
          true
        end,
        def has_constant?(:GROUP_PARTICIPANT_JOINED_GROUP_AND_PARENT_GROUP) do
          true
        end,
        def has_constant?(:MASKED_THREAD_CREATED) do
          true
        end,
        def has_constant?(:MASKED_THREAD_UNMASKED) do
          true
        end,
        def has_constant?(:BIZ_CHAT_ASSIGNMENT) do
          true
        end,
        def has_constant?(:CHAT_PSA) do
          true
        end,
        def has_constant?(:CHAT_POLL_CREATION_MESSAGE) do
          true
        end,
        def has_constant?(:CAG_MASKED_THREAD_CREATED) do
          true
        end,
        def has_constant?(:COMMUNITY_PARENT_GROUP_SUBJECT_CHANGED) do
          true
        end,
        def has_constant?(:CAG_INVITE_AUTO_ADD) do
          true
        end,
        def has_constant?(:BIZ_CHAT_ASSIGNMENT_UNASSIGN) do
          true
        end,
        def has_constant?(:CAG_INVITE_AUTO_JOINED) do
          true
        end,
        def has_constant?(:SCHEDULED_CALL_START_MESSAGE) do
          true
        end,
        def has_constant?(:COMMUNITY_INVITE_RICH) do
          true
        end,
        def has_constant?(:COMMUNITY_INVITE_AUTO_ADD_RICH) do
          true
        end,
        def has_constant?(:SUB_GROUP_INVITE_RICH) do
          true
        end,
        def has_constant?(:SUB_GROUP_PARTICIPANT_ADD_RICH) do
          true
        end,
        def has_constant?(:COMMUNITY_LINK_PARENT_GROUP_RICH) do
          true
        end,
        def has_constant?(:COMMUNITY_PARTICIPANT_ADD_RICH) do
          true
        end,
        def has_constant?(:SILENCED_UNKNOWN_CALLER_AUDIO) do
          true
        end,
        def has_constant?(:SILENCED_UNKNOWN_CALLER_VIDEO) do
          true
        end,
        def has_constant?(:GROUP_MEMBER_ADD_MODE) do
          true
        end,
        def has_constant?(:GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST_NON_ADMIN_ADD) do
          true
        end,
        def has_constant?(:COMMUNITY_CHANGE_DESCRIPTION) do
          true
        end,
        def has_constant?(:SENDER_INVITE) do
          true
        end,
        def has_constant?(:RECEIVER_INVITE) do
          true
        end,
        def has_constant?(:COMMUNITY_ALLOW_MEMBER_ADDED_GROUPS) do
          true
        end,
        def has_constant?(:PINNED_MESSAGE_IN_CHAT) do
          true
        end,
        def has_constant?(:PAYMENT_INVITE_SETUP_INVITER) do
          true
        end,
        def has_constant?(:PAYMENT_INVITE_SETUP_INVITEE_RECEIVE_ONLY) do
          true
        end,
        def has_constant?(:PAYMENT_INVITE_SETUP_INVITEE_SEND_AND_RECEIVE) do
          true
        end,
        def has_constant?(:LINKED_GROUP_CALL_START) do
          true
        end,
        def has_constant?(:REPORT_TO_ADMIN_ENABLED_STATUS) do
          true
        end,
        def has_constant?(:EMPTY_SUBGROUP_CREATE) do
          true
        end,
        def has_constant?(:SCHEDULED_CALL_CANCEL) do
          true
        end,
        def has_constant?(:SUBGROUP_ADMIN_TRIGGERED_AUTO_ADD_RICH) do
          true
        end,
        def has_constant?(:GROUP_CHANGE_RECENT_HISTORY_SHARING) do
          true
        end,
        def has_constant?(:PAID_MESSAGE_SERVER_CAMPAIGN_ID) do
          true
        end,
        def has_constant?(:GENERAL_CHAT_CREATE) do
          true
        end,
        def has_constant?(:GENERAL_CHAT_ADD) do
          true
        end,
        def has_constant?(:GENERAL_CHAT_AUTO_ADD_DISABLED) do
          true
        end,
        def has_constant?(:SUGGESTED_SUBGROUP_ANNOUNCE) do
          true
        end,
        def has_constant?(:BIZ_BOT_1P_MESSAGING_ENABLED) do
          true
        end,
        def has_constant?(:CHANGE_USERNAME) do
          true
        end,
        def has_constant?(:BIZ_COEX_PRIVACY_INIT_SELF) do
          true
        end,
        def has_constant?(:BIZ_COEX_PRIVACY_TRANSITION_SELF) do
          true
        end,
        def has_constant?(:SUPPORT_AI_EDUCATION) do
          true
        end,
        def has_constant?(:BIZ_BOT_3P_MESSAGING_ENABLED) do
          true
        end,
        def has_constant?(:REMINDER_SETUP_MESSAGE) do
          true
        end,
        def has_constant?(:REMINDER_SENT_MESSAGE) do
          true
        end,
        def has_constant?(:REMINDER_CANCEL_MESSAGE) do
          true
        end,
        def has_constant?(:BIZ_COEX_PRIVACY_INIT) do
          true
        end,
        def has_constant?(:BIZ_COEX_PRIVACY_TRANSITION) do
          true
        end,
        def has_constant?(:GROUP_DEACTIVATED) do
          true
        end,
        def has_constant?(:COMMUNITY_DEACTIVATE_SIBLING_GROUP) do
          true
        end,
        def has_constant?(:EVENT_UPDATED) do
          true
        end,
        def has_constant?(:EVENT_CANCELED) do
          true
        end,
        def has_constant?(:COMMUNITY_OWNER_UPDATED) do
          true
        end,
        def has_constant?(:COMMUNITY_SUB_GROUP_VISIBILITY_HIDDEN) do
          true
        end,
        def has_constant?(:CAPI_GROUP_NE2EE_SYSTEM_MESSAGE) do
          true
        end,
        def has_constant?(:STATUS_MENTION) do
          true
        end,
        def has_constant?(:USER_CONTROLS_SYSTEM_MESSAGE) do
          true
        end,
        def has_constant?(:SUPPORT_SYSTEM_MESSAGE) do
          true
        end,
        def has_constant?(:CHANGE_LID) do
          true
        end,
        def has_constant?(:BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_IN_MESSAGE) do
          true
        end,
        def has_constant?(:BIZ_CUSTOMER_3PD_DATA_SHARING_OPT_OUT_MESSAGE) do
          true
        end,
        def has_constant?(:CHANGE_LIMIT_SHARING) do
          true
        end,
        def has_constant?(:GROUP_MEMBER_LINK_MODE) do
          true
        end,
        def has_constant?(:BIZ_AUTOMATICALLY_LABELED_CHAT_SYSTEM_MESSAGE) do
          true
        end,
        def has_constant?(:PHONE_NUMBER_HIDING_CHAT_DEPRECATED_MESSAGE) do
          true
        end,
        def has_constant?(:QUARANTINED_MESSAGE) do
          true
        end,
        def has_constant?(:GROUP_MEMBER_SHARE_GROUP_HISTORY_MODE) do
          true
        end,
        def has_constant?(:GROUP_OPEN_BOT_ADDED) do
          true
        end,
        def has_constant?(:GROUP_TEE_BOT_ADDED) do
          true
        end,
        def has_constant?(:CONTACT_INFO) do
          true
        end,
        def has_constant?(:SCHEDULED_MESSAGE_CREATED) do
          true
        end,
        def has_constant?(:IDENTITY_TRUST_MARKED) do
          true
        end,
        def has_constant?(:IDENTITY_TRUST_UNMARKED) do
          true
        end,
        def has_constant?(:IDENTITY_TRUST_REVOKED) do
          true
        end,
        def has_constant?(:CTWA_CONSUMER_DISCLOSURE) do
          true
        end
      ]

      def has_constant?(_) do
        false
      end
    )
  )
end
