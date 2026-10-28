import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'modern_button.dart';
import 'modern_card.dart';
import 'modern_text_field.dart';

class UIShowcasePage extends StatelessWidget {
  const UIShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Showcase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient Cards
            const Text(
              ' Gradient Kartochkalar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const GradientCard(
              title: 'Jami xarajat',
              value: "172.000 so'm",
              icon: Icons.account_balance_wallet,
            ),
            const SizedBox(height: 12),
            const GradientCard(
              title: 'Tejamkorlik',
              value: "45.000 so'm",
              icon: Icons.savings,
              gradient: AppTheme.successGradient,
            ),

            const SizedBox(height: 24),

            // Tugmalar
            const Text(
              '🎨 Tugmalar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const ModernGradientButton(
              text: 'Asosiy tugma',
              icon: Icons.add,
              onPressed: null,
            ),
            const SizedBox(height: 12),
            const ModernGradientButton(
              text: 'Yuklanmoqda...',
              isLoading: true,
              onPressed: null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ModernOutlinedButton(
                    text: 'Bekor qilish',
                    icon: Icons.close,
                    onPressed: () {},
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModernOutlinedButton(
                    text: 'Saqlash',
                    icon: Icons.save,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ModernIconButton(
                  icon: Icons.edit,
                  onPressed: () {},
                  backgroundColor: AppTheme.warningColor,
                ),
                ModernIconButton(
                  icon: Icons.delete,
                  onPressed: () {},
                  backgroundColor: AppTheme.errorColor,
                ),
                ModernIconButton(
                  icon: Icons.share,
                  onPressed: () {},
                  backgroundColor: AppTheme.infoColor,
                ),
                ModernIconButton(
                  icon: Icons.favorite,
                  onPressed: () {},
                  backgroundColor: AppTheme.accentColor,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Input fieldlar
            const Text(
              '✏️ Input Fieldlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const ModernTextField(
              hintText: 'Email manzilingiz',
              labelText: 'Email',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            const ModernTextField(
              hintText: 'Parolingiz',
              labelText: 'Parol',
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            const ModernTextField(
              hintText: 'Izoh yozing...',
              labelText: 'Izoh',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Expense Card
            const Text(
              '💳 Xarajat Kartochkasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ExpenseCard(
              title: 'Oziq-ovqat',
              subtitle: 'Smenada abet va ujin',
              amount: "52.000 so'm",
              date: '25.10.2026 21:12',
              icon: Icons.restaurant,
              iconColor: AppTheme.primaryColor,
              onEdit: () {},
              onDelete: () {},
            ),
            ExpenseCard(
              title: 'Yo\'l',
              subtitle: 'Smenga borib kelish',
              amount: "48.000 so'm",
              date: '26.10.2026 12:19',
              icon: Icons.commute,
              iconColor: AppTheme.infoColor,
              onEdit: () {},
              onDelete: () {},
            ),

            const SizedBox(height: 24),

            // Glassmorphism (gradient fon ustida)
            const Text(
              '✨ Glassmorphism (Gradient fon ustida)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const GlassmorphismButton(
                    text: 'Google bilan kirish',
                    icon: Icons.login,
                    onPressed: null,
                  ),
                  const SizedBox(height: 12),
                  const GlassmorphismButton(
                    text: 'Davom etish',
                    onPressed: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}