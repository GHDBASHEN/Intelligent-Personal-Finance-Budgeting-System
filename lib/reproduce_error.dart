import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState {}

class MyNotifier extends Notifier<MyState> {
  @override
  MyState build() => MyState();
}

final myProvider = NotifierProvider<MyNotifier, MyState>(MyNotifier.new);

void main() {
  print('Success');
}
