import 'package:gmail_client/gmail_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// State for the inbox provider.
class InboxState {
  final List<EmailMessage> emails;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool noTokens;
  final String? nextPageToken;

  const InboxState({
    this.emails = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.noTokens = false,
    this.nextPageToken,
  });

  InboxState copyWith({
    List<EmailMessage>? emails,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? noTokens,
    String? nextPageToken,
    bool clearError = false,
  }) {
    return InboxState(
      emails: emails ?? this.emails,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      noTokens: noTokens ?? this.noTokens,
      nextPageToken: nextPageToken ?? this.nextPageToken,
    );
  }
}

/// Notifier that manages inbox state (email list, pagination, loading).
///
/// Call [load] to fetch the first page. Call [loadMore] for subsequent pages.
class InboxNotifier extends StateNotifier<InboxState> {
  final Ref _ref;

  InboxNotifier(this._ref) : super(const InboxState());

  /// Fetches the first page of emails.
  Future<void> load() => _fetch();

  /// Refreshes from the first page (same as [load]).
  Future<void> refresh() => _fetch();

  /// Fetches the next page, if available.
  Future<void> loadMore() {
    if (state.nextPageToken == null || state.isLoadingMore) {
      return Future.value();
    }
    return _fetch(pageToken: state.nextPageToken);
  }

  Future<void> _fetch({String? pageToken}) async {
    state = state.copyWith(
      isLoading: pageToken == null,
      isLoadingMore: pageToken != null,
      clearError: true,
    );

    try {
      final service = _ref.read(emailServiceProvider);
      final result = await service.listEmails(
        maxResults: 30,
        pageToken: pageToken,
      );

      state = state.copyWith(
        emails: pageToken != null
            ? [...state.emails, ...result.messages]
            : result.messages,
        isLoading: false,
        isLoadingMore: false,
        nextPageToken: result.nextPageToken,
      );
    } on GmailTokenException catch (e) {
      state = state.copyWith(
        noTokens: true,
        isLoading: false,
        isLoadingMore: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isLoadingMore: false,
      );
    }
  }
}

/// Provider for the inbox state.
///
/// Does NOT auto-load. Call `ref.read(inboxProvider.notifier).load()` to start.
final inboxProvider =
    StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  return InboxNotifier(ref);
});
