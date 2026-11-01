library entitlement_service;

/// Manages the prototype-tier entitlement tracking for free AI floor plan generations.
///
/// IMPORTANT PROTOTYPE DISCLOSURE:
/// In accordance with final year project boundaries, this client-side entitlement counter
/// serves as a demonstration of the freemium business model (2 free AI generations).
/// It does NOT claim to provide cryptographic or backend-enforced subscription security.
/// In production, user quotas are governed by Cloud Firestore server-side security rules
/// and Firebase Auth claims.
class EntitlementService {
  static const int maxFreeGenerations = 2;
  int get maxFreeQuota => maxFreeGenerations;
  int _usedGenerations = 0;

  int get usedGenerations => _usedGenerations;
  int get remainingFreeGenerations => (maxFreeGenerations - _usedGenerations).clamp(0, maxFreeGenerations);
  bool get canGenerateFree => _usedGenerations < maxFreeGenerations;

  /// Records an AI generation attempt
  void recordGeneration() {
    _usedGenerations++;
  }

  /// Resets the counter for testing and evaluation purposes
  void resetPrototypeTier() {
    _usedGenerations = 0;
  }
}
