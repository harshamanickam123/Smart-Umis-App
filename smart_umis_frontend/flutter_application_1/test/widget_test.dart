import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  group('Smart UMIS Complete Widget Tests', () {
    // ============================================
    // PAGE 1: WELCOME SCREEN TESTS
    // ============================================
    group('Welcome Screen Tests', () {
      testWidgets('Welcome screen displays all required elements',
          (WidgetTester tester) async {
        await tester.pumpWidget(const SmartUMISApp());

        // Verify app title and branding
        expect(find.text('Smart UMIS'), findsOneWidget);
        expect(find.text('Data Entry System'), findsOneWidget);
        expect(find.text('Welcome'), findsOneWidget);

        // Verify description
        expect(
          find.textContaining('Please login or register'),
          findsOneWidget,
        );

        // Verify buttons
        expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
        expect(find.widgetWithText(OutlinedButton, 'Register'), findsOneWidget);

        // Verify icons
        expect(find.byIcon(Icons.school), findsOneWidget);
        expect(find.byIcon(Icons.login), findsOneWidget);
        expect(find.byIcon(Icons.person_add), findsOneWidget);
      });

      testWidgets('Login button navigates to Login screen',
          (WidgetTester tester) async {
        await tester.pumpWidget(const SmartUMISApp());

        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        expect(find.text('Login to your account'), findsOneWidget);
      });

      testWidgets('Register button navigates to Register screen',
          (WidgetTester tester) async {
        await tester.pumpWidget(const SmartUMISApp());

        await tester.tap(find.widgetWithText(OutlinedButton, 'Register'));
        await tester.pumpAndSettle();

        expect(find.text('Create your account'), findsOneWidget);
      });
    });

    // ============================================
    // PAGE 2: LOGIN SCREEN TESTS
    // ============================================
    group('Login Screen Tests', () {
      testWidgets('Login screen displays all required fields',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        expect(find.text('Smart UMIS'), findsOneWidget);
        expect(find.text('Login to your account'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Enter your username'), findsOneWidget);
        expect(find.text('Enter your password'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsOneWidget);
      });

      testWidgets('Password visibility toggle works',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        expect(find.byIcon(Icons.visibility_off), findsOneWidget);

        await tester.ensureVisible(find.byIcon(Icons.visibility_off));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();

        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });

      testWidgets('Empty fields show validation errors',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        await tester
            .ensureVisible(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter username'), findsOneWidget);
        expect(find.text('Please enter password'), findsOneWidget);
      });

      testWidgets('Navigate to register screen from login',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        await tester.ensureVisible(find.text('Register here'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Register here'));
        await tester.pumpAndSettle();

        expect(find.text('Create your account'), findsOneWidget);
      });

      testWidgets('Back button returns to previous screen',
          (WidgetTester tester) async {
        await tester.pumpWidget(const SmartUMISApp());

        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.text('Welcome'), findsOneWidget);
      });
    });

    // ============================================
    // PAGE 3: REGISTER SCREEN TESTS
    // ============================================
    group('Register Screen Tests', () {
      testWidgets('Register screen displays all required fields',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

        expect(find.text('Smart UMIS'), findsOneWidget);
        expect(find.text('Create your account'), findsOneWidget);
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Role'), findsOneWidget);
        expect(find.text('Password'), findsAtLeast(1));
        expect(find.text('Confirm Password'), findsOneWidget);
        expect(find.text('Student'), findsOneWidget);
        expect(find.text('Staff'), findsOneWidget);
      });

      testWidgets('Role selection works correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

        await tester.ensureVisible(find.text('Role'));
        await tester.pumpAndSettle();

        // Tap Staff
        await tester.tap(find.text('Staff'));
        await tester.pump();
        expect(find.text('Staff'), findsOneWidget);

        // Tap Student
        await tester.tap(find.text('Student'));
        await tester.pump();
        expect(find.text('Student'), findsOneWidget);
      });

      testWidgets('Password visibility toggles work',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

        await tester.ensureVisible(
          find.widgetWithText(TextFormField, 'Enter your password'),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));

        final visibilityToggles = find.byIcon(Icons.visibility_off);
        await tester.tap(visibilityToggles.first);
        await tester.pump();

        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });

      testWidgets('Email validation works', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

        await tester.ensureVisible(
          find.widgetWithText(TextFormField, 'Enter your email'),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your email'),
          'invalidemail',
        );

        await tester
            .ensureVisible(find.widgetWithText(ElevatedButton, 'Register'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.widgetWithText(TextFormField, 'Enter your email'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Please enter a valid email'), findsOneWidget);
      });

      testWidgets('Navigate to login screen from register',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

        await tester.ensureVisible(find.text('Login here'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Login here'));
        await tester.pumpAndSettle();

        expect(find.text('Login to your account'), findsOneWidget);
      });
    });

    // ============================================
    // PAGE 4: DASHBOARD SCREEN TESTS
    // ============================================
    group('Dashboard Screen Tests', () {
      testWidgets('Dashboard displays correctly with user data',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: DashboardScreen(userData: userData),
          ),
        );

        expect(find.text('Smart UMIS'), findsOneWidget);
        expect(find.text('Welcome, Data Entry User!'), findsOneWidget);
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Select a module to get started.'), findsOneWidget);
      });

      testWidgets('Dashboard displays all 4 module cards',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: DashboardScreen(userData: userData),
          ),
        );

        expect(find.text('Student Records'), findsOneWidget);
        expect(find.text('Staff Check'), findsOneWidget);
        expect(find.text('QR Verification'), findsOneWidget);
        expect(find.text('Token Generation'), findsOneWidget);

        // Verify subtitles
        expect(find.text('View/Edit student records.'), findsOneWidget);
        expect(find.text('View/Edit staff records'), findsOneWidget);
      });

      testWidgets('Bottom navigation bar works correctly',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: DashboardScreen(userData: userData),
          ),
        );

        // Verify bottom navigation items
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Data Entry'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        // Tap Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Verify profile screen - use findsAtLeast for text that may appear multiple times
        expect(find.text('John Doe'), findsWidgets);
        expect(find.text('john@example.com'), findsAtLeast(1));
        expect(find.text('Student'), findsWidgets);

        // Tap Home tab
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();

        // Back to dashboard
        expect(find.text('Dashboard'), findsOneWidget);
      });

      testWidgets('Profile tab displays user information',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'Jane Smith',
          'username': 'janesmith',
          'email': 'jane@example.com',
          'role': 'Staff',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: DashboardScreen(userData: userData),
          ),
        );

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        expect(find.text('Jane Smith'), findsWidgets);
        expect(find.text('jane@example.com'), findsAtLeast(1));
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('janesmith'), findsOneWidget);
        expect(find.text('Role'), findsOneWidget);
        expect(find.text('Staff'), findsWidgets);
      });

      testWidgets('Student Records card navigates to data entry',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: DashboardScreen(userData: userData),
          ),
        );

        await tester.tap(find.text('Student Records'));
        await tester.pumpAndSettle();

        // Use findsAtLeast because text appears in both AppBar and body
        expect(find.text('Student Data Entry'), findsAtLeast(1));
        expect(find.text('Choose Department'), findsOneWidget);
      });

      testWidgets('Logout button works from profile',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: DashboardScreen(userData: userData),
          ),
        );

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Scroll to find the logout button
        await tester.dragUntilVisible(
          find.byIcon(Icons.logout),
          find.byType(SingleChildScrollView).last,
          const Offset(0, -50),
        );
        await tester.pumpAndSettle();

        // Tap the logout icon
        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();

        expect(find.text('Welcome'), findsOneWidget);
      });
    });

    // ============================================
    // PAGE 5: STUDENT DATA ENTRY TESTS
    // ============================================
    group('Student Data Entry Screen Tests', () {
      testWidgets('Student data entry screen displays all fields',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: StudentDataEntryScreen(userData: userData),
          ),
        );

        expect(find.text('Student Data Entry'), findsAtLeast(1));
        expect(find.text('Enter and manage student details'), findsOneWidget);
        expect(find.text('Choose Department'), findsOneWidget);
        expect(find.text('UMIS Details'), findsOneWidget);
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('Father Name'), findsOneWidget);
        expect(find.text('Caste'), findsOneWidget);
        expect(find.text("Mother's Occupation"), findsOneWidget);
        expect(find.text("Father's Occupation"), findsOneWidget);
      });

      testWidgets('Department dropdown works correctly',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: StudentDataEntryScreen(userData: userData),
          ),
        );

        // Scroll to make dropdown visible
        await tester.ensureVisible(find.text('Select Department'));
        await tester.pumpAndSettle();

        // Tap dropdown - use byType instead
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();

        // Verify dropdown items
        expect(find.text('CSI - Computer Science'), findsOneWidget);
        expect(find.text('ECE - Electronics'), findsOneWidget);
        expect(find.text('VS - Visual Communication'), findsOneWidget);

        // Select an item
        await tester.tap(find.text('CSI - Computer Science').last);
        await tester.pumpAndSettle();

        expect(find.text('CSI - Computer Science'), findsOneWidget);
      });

      testWidgets('Document upload buttons are displayed',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: StudentDataEntryScreen(userData: userData),
          ),
        );

        await tester.ensureVisible(find.text('12th Marksheet'));
        await tester.pumpAndSettle();

        expect(find.text('12th Marksheet'), findsOneWidget);
        expect(find.text('Aadhar Certificate'), findsOneWidget);
        expect(find.text('PAN Card Certificate'), findsOneWidget);

        // Verify upload buttons
        expect(find.text('Upload'), findsNWidgets(3));
      });

      testWidgets('Form validation works for required fields',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: StudentDataEntryScreen(userData: userData),
          ),
        );

        // Scroll to submit button
        await tester.ensureVisible(
          find.widgetWithText(ElevatedButton, 'Save & Submit Data'),
        );
        await tester.pumpAndSettle();

        // Tap submit without filling form
        await tester
            .tap(find.widgetWithText(ElevatedButton, 'Save & Submit Data'));
        await tester.pumpAndSettle();

        // Should show validation error snackbar
        expect(find.text('Please fill all required fields'), findsOneWidget);
      });

      testWidgets('Form accepts input in all fields',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: StudentDataEntryScreen(userData: userData),
          ),
        );

        // Fill Full Name
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter student full name'),
          'Test Student',
        );
        expect(find.text('Test Student'), findsOneWidget);

        // Fill Father Name
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter father name'),
          'Test Father',
        );
        expect(find.text('Test Father'), findsOneWidget);

        // Fill Caste
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter caste'),
          'General',
        );
        expect(find.text('General'), findsOneWidget);
      });

      testWidgets('Back button returns to dashboard',
          (WidgetTester tester) async {
        final userData = {
          'fullName': 'John Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'role': 'Student',
        };

        await tester.pumpWidget(
          MaterialApp(
            home: StudentDataEntryScreen(userData: userData),
          ),
        );

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should go back (in real app to dashboard)
        expect(find.byType(StudentDataEntryScreen), findsNothing);
      });
    });

    // ============================================
    // NAVIGATION FLOW TESTS
    // ============================================
    group('Complete Navigation Flow Tests', () {
      testWidgets('Full app navigation flow works',
          (WidgetTester tester) async {
        await tester.pumpWidget(const SmartUMISApp());

        // Start at Welcome
        expect(find.text('Welcome'), findsOneWidget);

        // Navigate to Login
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();
        expect(find.text('Login to your account'), findsOneWidget);

        // Navigate to Register
        await tester.ensureVisible(find.text('Register here'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Register here'));
        await tester.pumpAndSettle();
        expect(find.text('Create your account'), findsOneWidget);

        // Back to Login
        await tester.ensureVisible(find.text('Login here'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Login here'));
        await tester.pumpAndSettle();
        expect(find.text('Login to your account'), findsOneWidget);

        // Back to Welcome
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Welcome'), findsOneWidget);
      });
    });

    // ============================================
    // UI/UX TESTS
    // ============================================
    group('UI and Theme Tests', () {
      testWidgets('App uses correct theme colors', (WidgetTester tester) async {
        await tester.pumpWidget(const SmartUMISApp());

        final MaterialApp app = tester.widget(find.byType(MaterialApp));
        expect(app.theme?.primaryColor, const Color(0xFF2E7D32));
      });

      testWidgets('Icons are displayed correctly', (WidgetTester tester) async {
        await tester.pumpWidget(const SmartUMISApp());

        expect(find.byIcon(Icons.school), findsOneWidget);
        expect(find.byIcon(Icons.login), findsOneWidget);
        expect(find.byIcon(Icons.person_add), findsOneWidget);
      });
    });
  });
}
