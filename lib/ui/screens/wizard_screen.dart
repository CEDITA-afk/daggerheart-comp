import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';
import 'character_sheet_screen.dart';

import '../widgets/step_class_selection.dart';
import '../widgets/step_subclass.dart';
import '../widgets/step_ancestry_community.dart';
import '../widgets/step_traits_allocation.dart';
import '../widgets/step_derived_stats.dart';
import '../widgets/step_equipment.dart';
import '../widgets/step_background.dart';
import '../widgets/step_experiences.dart';
import '../widgets/step_card_selection.dart';
import '../widgets/step_bonds.dart';

class WizardScreen extends StatelessWidget {
  const WizardScreen({super.key});

  final int totalSteps = 10;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreationProvider(),
      child: Consumer<CreationProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: Text(
                "CREAZIONE - STEP ${provider.currentStep + 1}/$totalSteps",
                style: const TextStyle(fontFamily: 'Cinzel', fontSize: 16),
              ),
              centerTitle: true,
              leading: provider.currentStep > 0
                  ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: provider.prevStep)
                  : IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ),
            body: Column(
              children: [
                LinearProgressIndicator(
                  value: (provider.currentStep + 1) / totalSteps,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                ),
                
                // MOSTRA ERRORE SE PRESENTE
                if (provider.validationError != null)
                  Container(
                    width: double.infinity,
                    color: Colors.redAccent.withOpacity(0.8),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      provider.validationError!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStepContent(provider.currentStep),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  if (provider.currentStep < totalSteps - 1) {
                    provider.nextStep(); // La logica di validazione è dentro nextStep()
                  } else {
                    // Validazione finale prima del salvataggio
                    if (provider.validateCurrentStep()) {
                      await provider.saveCharacter();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CharacterSheetScreen(character: provider.draftCharacter),
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text(provider.currentStep == totalSteps - 1 ? "TERMINA" : "CONTINUA"),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0: return const StepClassSelection();
      case 1: return const StepSubclass();
      case 2: return const StepAncestryCommunity();
      case 3: return const StepTraitsAllocation();
      case 4: return const StepDerivedStats();
      case 5: return const StepEquipment();
      case 6: return const StepBackground();
      case 7: return const StepExperiences();
      case 8: return const StepCardSelection();
      case 9: return const StepBonds();
      default: return const SizedBox.shrink();
    }
  }
}