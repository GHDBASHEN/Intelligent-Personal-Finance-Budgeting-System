import 'dart:isolate';

void main() async {
  var uri = await Isolate.resolvePackageUri(Uri.parse('package:csv/csv.dart'));
  print('Package URI: $uri');
}
