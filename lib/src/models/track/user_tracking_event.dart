abstract class UserTrackingEvent {
  String eventName();
}

class UserLoggedIn extends UserTrackingEvent {
  @override
  String eventName() => "UserLoggedIn";
}
class UserLoggedOut extends UserTrackingEvent {
  @override
  String eventName() => "UserLoggedOut";
}
class ViewNotifications extends UserTrackingEvent {
  @override
  String eventName() => "ViewNotifications";
}
class ViewChatHome extends UserTrackingEvent {
  @override
  String eventName() => "ViewChatHome";
}
class EnterChatRoom extends UserTrackingEvent {
  @override
  String eventName() => "EnterChatRoom";
}
class AttemptToCreateChatRoom extends UserTrackingEvent {
  @override
  String eventName() => "AttemptToCreateChatRoom";
}
class CreateChatRoom extends UserTrackingEvent {
  @override
  String eventName() => "CreateChatRoom";
}
class ViewDiaryHome extends UserTrackingEvent {
  @override
  String eventName() => "ViewDiaryHome";
}
class SearchForExercise extends UserTrackingEvent {
  @override
  String eventName() => "SearchForExercise";
}
class SearchForFood extends UserTrackingEvent {
  @override
  String eventName() => "SearchForFood";
}
class CreateFoodDiaryEntry extends UserTrackingEvent {
  @override
  String eventName() => "CreateFoodDiaryEntry";
}
class CreateExerciseDiaryEntry extends UserTrackingEvent {
  @override
  String eventName() => "CreateExerciseDiaryEntry";
}
class ViewDiaryEntry extends UserTrackingEvent {
  @override
  String eventName() => "ViewDiaryEntry";
}
class EditDiaryEntry extends UserTrackingEvent {
  @override
  String eventName() => "EditDiaryEntry";
}
class ViewDiaryDailySummary extends UserTrackingEvent {
  @override
  String eventName() => "ViewDiaryDailySummary";
}
class UpdateFitnessUserProfile extends UserTrackingEvent {
  @override
  String eventName() => "UpdateFitnessUserProfile";
}
class ViewMeetupHome extends UserTrackingEvent {
  @override
  String eventName() => "ViewMeetupHome";
}
class AttemptToCreateMeetup extends UserTrackingEvent {
  @override
  String eventName() => "AttemptToCreateMeetup";
}
class CreateMeetup extends UserTrackingEvent {
  @override
  String eventName() => "CreateMeetup";
}
class ViewDetailedMeetup extends UserTrackingEvent {
  @override
  String eventName() => "ViewDetailedMeetup";
}
class EditMeetup extends UserTrackingEvent {
  @override
  String eventName() => "EditMeetup";
}
class RespondToMeetup extends UserTrackingEvent {
  @override
  String eventName() => "RespondToMeetup";
}
class CommentOnMeetup extends UserTrackingEvent {
  @override
  String eventName() => "CommentOnMeetup";
}
class AddAvailabilityToMeetup extends UserTrackingEvent {
  @override
  String eventName() => "AddAvailabilityToMeetup";
}
class AssociateDiaryEntryToMeetup extends UserTrackingEvent {
  @override
  String eventName() => "AssociateDiaryEntryToMeetup";
}
class ViewNewsfeedHome extends UserTrackingEvent {
  @override
  String eventName() => "ViewNewsfeedHome";
}
class LikeSocialPost extends UserTrackingEvent {
  @override
  String eventName() => "LikeSocialPost";
}
class AddSocialPostComment extends UserTrackingEvent {
  @override
  String eventName() => "AddSocialPostComment";
}
class AttemptToCreatePost extends UserTrackingEvent {
  @override
  String eventName() => "AttemptToCreatePost";
}
class CreatePost extends UserTrackingEvent {
  @override
  String eventName() => "CreatePost";
}
class ViewCurrentUserAccountDetails extends UserTrackingEvent {
  @override
  String eventName() => "ViewCurrentUserAccountDetails";
}
class AttemptToActivatePremium extends UserTrackingEvent {
  @override
  String eventName() => "AttemptToActivatePremium";
}
class ActivatePremium extends UserTrackingEvent {
  @override
  String eventName() => "ActivatePremium";
}
class EditCurrentUserAccountDetails extends UserTrackingEvent {
  @override
  String eventName() => "EditCurrentUserAccountDetails";
}
class ViewOtherUserProfile extends UserTrackingEvent {
  @override
  String eventName() => "ViewOtherUserProfile";
}
class SendFriendRequestToUser extends UserTrackingEvent {
  @override
  String eventName() => "SendFriendRequestToUser";
}
class AcceptUserFriendRequest extends UserTrackingEvent {
  @override
  String eventName() => "AcceptUserFriendRequest";
}
class DeclineUserFriendRequest extends UserTrackingEvent {
  @override
  String eventName() => "DeclineUserFriendRequest";
}
class UpdateDiscoveryPreferences extends UserTrackingEvent {
  @override
  String eventName() => "UpdateDiscoveryPreferences";
}
class AttemptToDiscoverUsers extends UserTrackingEvent {
  @override
  String eventName() => "AttemptToDiscoverUsers";
}
class ViewNewDiscoveredUser extends UserTrackingEvent {
  @override
  String eventName() => "ViewNewDiscoveredUser";
}
class AcceptNewDiscoveredUser extends UserTrackingEvent {
  @override
  String eventName() => "AcceptNewDiscoveredUser";
}
class RejectNewDiscoveredUser extends UserTrackingEvent {
  @override
  String eventName() => "RejectNewDiscoveredUser";
}
class RemoveFromNewlyDiscoveredUsers extends UserTrackingEvent {
  @override
  String eventName() => "RemoveFromNewlyDiscoveredUsers";
}
class LeaveChatRoom extends UserTrackingEvent {
  @override
  String eventName() => "LeaveChatRoom";
}
class SearchForUsers extends UserTrackingEvent {
  @override
  String eventName() => "SearchForUsers";
}
class ViewCalendar extends UserTrackingEvent {
  @override
  String eventName() => "ViewCalendar";
}
class ViewFriends extends UserTrackingEvent {
  @override
  String eventName() => "ViewFriends";
}
class CancelPremium extends UserTrackingEvent {
  @override
  String eventName() => "CancelPremium";
}
class ViewAchievements extends UserTrackingEvent {
  @override
  String eventName() => "ViewAchievements";
}
class ViewDetailedStepAchievements extends UserTrackingEvent {
  @override
  String eventName() => "ViewDetailedStepAchievements";
}
class ViewDetailedDiaryAchievements extends UserTrackingEvent {
  @override
  String eventName() => "ViewDetailedDiaryAchievements";
}
class ViewDetailedActivityAchievements extends UserTrackingEvent {
  @override
  String eventName() => "ViewDetailedActivityAchievements";
}
class ViewDetailedWeightAchievements extends UserTrackingEvent {
  @override
  String eventName() => "ViewDetailedWeightAchievements";
}
class ViewProgress extends UserTrackingEvent {
  @override
  String eventName() => "ViewProgress";
}
class ViewDetailedStepProgress extends UserTrackingEvent {
  @override
  String eventName() => "ViewDetailedStepProgress";
}
class ViewDetailedDiaryProgress extends UserTrackingEvent {
  @override
  String eventName() => "ViewDetailedDiaryProgress";
}
class ViewDetailedActivityProgress extends UserTrackingEvent {
  @override
  String eventName() => "ViewDetailedActivityProgress";
}
class ViewDetailedWeightProgress extends UserTrackingEvent {
  @override
  String eventName() => "ViewDetailedWeightProgress";
}