// lib/presentation/viewmodels/delete_post_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/delete_post_response.dart';
import '../repositories/delete_post_repository.dart';


// States
abstract class DeletePostState {
  const DeletePostState();
}

class DeletePostInitial extends DeletePostState {}

class DeletePostLoading extends DeletePostState {}

class DeletePostSuccess extends DeletePostState {
  final DeletePostResponse response;
  const DeletePostSuccess(this.response);
}

class DeletePostError extends DeletePostState {
  final String message;
  const DeletePostError(this.message);
}

// ViewModel
class DeletePostViewModel extends StateNotifier<DeletePostState> {
  final DeletePostRepository _repository;

  DeletePostViewModel(this._repository) : super(DeletePostInitial());

  Future<void> deletePost(int postId) async {
    state = DeletePostLoading();
    try {
      final response = await _repository.deletePost(postId);
      if (response.success) {
        state = DeletePostSuccess(response);
      } else {
        state = DeletePostError(response.message);
      }
    } catch (e) {
      state = DeletePostError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void resetState() {
    state = DeletePostInitial();
  }
}