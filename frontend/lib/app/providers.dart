import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/realtime/websocket_manager.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/donor_repository.dart';
import '../data/repositories/request_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/chat_service.dart';
import '../data/services/donor_service.dart';
import '../data/services/request_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.instance);

final websocketManagerProvider = Provider<WebSocketManager>(
  (ref) => WebSocketManager.instance,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(apiClientProvider)),
);

final donorServiceProvider = Provider<DonorService>(
  (ref) => DonorService(ref.watch(apiClientProvider)),
);

final requestServiceProvider = Provider<RequestService>(
  (ref) => RequestService(ref.watch(apiClientProvider)),
);

final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authServiceProvider)),
);

final donorRepositoryProvider = Provider<DonorRepository>(
  (ref) => DonorRepository(ref.watch(donorServiceProvider)),
);

final requestRepositoryProvider = Provider<RequestRepository>(
  (ref) => RequestRepository(ref.watch(requestServiceProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(chatServiceProvider)),
);
