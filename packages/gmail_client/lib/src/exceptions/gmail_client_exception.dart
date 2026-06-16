class GmailClientException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const GmailClientException(this.message, {this.code, this.details});

  @override
  String toString() => 'GmailClientException($code): $message';
}

class GmailAuthException extends GmailClientException {
  const GmailAuthException(super.message, {super.code, super.details});
}

class GmailSendException extends GmailClientException {
  const GmailSendException(super.message, {super.code, super.details});
}

class GmailTokenException extends GmailClientException {
  const GmailTokenException(super.message, {super.code, super.details});
}

class GmailConfigException extends GmailClientException {
  const GmailConfigException(super.message, {super.code, super.details});
}
