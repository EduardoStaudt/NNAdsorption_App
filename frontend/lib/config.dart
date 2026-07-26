const bool kIsProduction = bool.fromEnvironment('dart.vm.product');

const String kBackendUrl = kIsProduction
    ? 'https://nnadsorption-app.onrender.com'
    : 'http://localhost:8000';
