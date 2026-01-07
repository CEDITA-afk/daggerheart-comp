import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/character.dart';
import '../data/data_manager.dart';

class PdfExportService {
  
  // Abilità standard per ogni attributo (da NEUTRA.pdf)
  static final Map<String, List<String>> _attributeSkills = {
    "AGILITÀ": ["Scattare", "Saltare", "Destreggiarsi"],
    "FORZA": ["Sollevare", "Colpire", "Afferrare"],
    "ASTUZIA": ["Nascondersi", "Orientarsi", "Ingannare"],
    "ISTINTO": ["Percepire", "Intuire", "Sopravvivere"],
    "PRESENZA": ["Affascinare", "Esibirsi", "Calmare"],
    "CONOSCENZA": ["Ricordare", "Analizzare", "Comprendere"],
  };

  static Future<pw.Document> _generateDocument(Character char) async {
    final pdf = pw.Document();
    
    // Recupera i dati completi
    final classData = DataManager().getClassById(char.classId);
    final className = classData?['name'] ?? char.classId.toUpperCase();
    
    final ancestryData = DataManager().getAncestryById(char.ancestryId);
    final ancestryName = ancestryData?['name'] ?? char.ancestryId;
    
    final communityData = DataManager().getCommunityById(char.communityId);
    final communityName = communityData?['name'] ?? char.communityId;
    // Recupera sottoclasse
    final subclasses = classData?['subclasses'] as List? ?? [];
    final subclassData = subclasses.firstWhere(
      (s) => s['id'] == char.subclassId, 
      orElse: () => null
    );
    final subclassName = subclassData?['name'] ?? "";

    // Font Ufficiali-like (Cinzel per titoli, Lato per corpo)
    final fontTitle = await PdfGoogleFonts.cinzelDecorativeBold();
    final fontBody = await PdfGoogleFonts.latoRegular();
    final fontBold = await PdfGoogleFonts.latoBold();
    final fontItalic = await PdfGoogleFonts.latoItalic();

    // Stili
    final styleLabel = pw.TextStyle(font: fontBold, fontSize: 6, color: PdfColors.grey700);
    final styleValue = pw.TextStyle(font: fontBody, fontSize: 10);
    final styleHeader = pw.TextStyle(font: fontTitle, fontSize: 18);

    // --- PAGINA 1: SCHEDA GRAFICA (Layout NEUTRA.pdf) ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. HEADER (Nome, Classe, Livello)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(child: _buildUnderlinedField("NOME PERSONAGGIO", char.name, fontTitle, 16)),
                  pw.SizedBox(width: 15),
                  pw.Expanded(child: _buildUnderlinedField("PRONOMI", char.pronouns, fontBody, 10)),
                  pw.SizedBox(width: 15),
                  pw.Expanded(child: _buildUnderlinedField("CLASSE", className, fontBody, 12)),
                ]
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(child: _buildUnderlinedField("RETAGGIO", ancestryName, fontBody, 12)),
                  pw.SizedBox(width: 15),
                  pw.Expanded(child: _buildUnderlinedField("COMUNITÀ", communityName, fontBody, 12)),
                  pw.SizedBox(width: 15),
                  pw.Container(
                    width: 50,
                    child: _buildUnderlinedField("LIVELLO", "${char.level}", fontTitle, 18)
                  ),
                ]
              ),
              // HEADER (Aggiungi Sottoclasse)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(child: _buildUnderlinedField("CLASSE", className, fontBody, 12)),
                  pw.SizedBox(width: 15),
                  pw.Expanded(child: _buildUnderlinedField("SOTTOCLASSE", subclassName, fontBody, 12)), // <--- QUI
                ]
              ),
              
              pw.Divider(color: PdfColors.grey, thickness: 1, height: 25),

              // 2. CORPO CENTRALE
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // --- COLONNA SINISTRA: ATTRIBUTI ---
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        children: [
                          _buildAttributeBox("AGILITÀ", char.traits['agilita'] ?? 0, fontBold, fontBody),
                          _buildAttributeBox("FORZA", char.traits['forza'] ?? 0, fontBold, fontBody),
                          _buildAttributeBox("ASTUZIA", char.traits['astuzia'] ?? 0, fontBold, fontBody),
                          _buildAttributeBox("ISTINTO", char.traits['istinto'] ?? 0, fontBold, fontBody),
                          _buildAttributeBox("PRESENZA", char.traits['presenza'] ?? 0, fontBold, fontBody),
                          _buildAttributeBox("CONOSCENZA", char.traits['conoscenza'] ?? 0, fontBold, fontBody),
                        ],
                      ),
                    ),
                    
                    pw.SizedBox(width: 25),

                    // --- COLONNA DESTRA: STATS, SOGLIE, ARMI ---
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        children: [
                          // Statistiche Vitali (Evasione, Armatura, Speranza)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatBox("EVASIONE", "${10 + (char.traits['agilita']??0) + char.evasionModifier}", "Inizia a 10", fontBold, fontBody),
                              _buildStatBox("ARMATURA", "${char.armorScore}", "Slot Armatura", fontBold, fontBody),
                              _buildStatBox("SPERANZA", "${char.hope}", "Max 6", fontBold, fontBody, borderColor: PdfColors.amber),
                            ]
                          ),
                          pw.SizedBox(height: 15),

                          // Risorse (PF e Stress)
                          _buildTrackerBar("PUNTI FERITA", char.currentHp, char.maxHp, PdfColors.red200, fontBold),
                          pw.SizedBox(height: 8),
                          _buildTrackerBar("STRESS", char.currentStress, char.maxStress, PdfColors.purple200, fontBold),
                          
                          pw.SizedBox(height: 20),

                          // Soglie di Danno (Box come nel PDF)
                          pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey400),
                              borderRadius: pw.BorderRadius.circular(6)
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text("SOGLIE DI DANNO", style: pw.TextStyle(font: fontBold, fontSize: 8)),
                                pw.SizedBox(height: 6),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildDamageThreshold("MINORE", "1 - ${_calcMinor(char)}", fontBold),
                                    _buildDamageThreshold("MAGGIORE", "${_calcMinor(char)+1} - ${_calcMajor(char)-1}", fontBold),
                                    _buildDamageThreshold("GRAVE", "${_calcMajor(char)} +", fontBold),
                                  ]
                                )
                              ]
                            )
                          ),

                          pw.SizedBox(height: 20),

                          // Armi Equipaggiate
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            color: PdfColors.grey200,
                            child: pw.Text("ARMI EQUIPAGGIATE", style: pw.TextStyle(font: fontBold, fontSize: 10))
                          ),
                          pw.SizedBox(height: 5),
                          if (char.weapons.isEmpty) 
                            pw.Text("- Nessuna arma -", style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey))
                          else
                            ...char.weapons.map((w) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Row(children: [
                                pw.Container(width: 4, height: 4, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle)),
                                pw.SizedBox(width: 6),
                                pw.Text(w, style: styleValue)
                              ])
                            )),
                            
                          pw.Spacer(),

                          // Esperienze (Sulla prima pagina come nel PDF originale)
                          pw.Container(
                            width: double.infinity,
                            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            color: PdfColors.grey200,
                            child: pw.Text("ESPERIENZE", style: pw.TextStyle(font: fontBold, fontSize: 10))
                          ),
                          pw.SizedBox(height: 5),
                          ...char.experiences.where((e) => e.isNotEmpty).map((e) => pw.Text("• $e", style: styleValue)),
                          pw.SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 3. FOOTER (Inventario Rapido)
              pw.Divider(color: PdfColors.grey, thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("ORO", style: styleLabel),
                    pw.Text("${char.gold}", style: pw.TextStyle(font: fontBold, fontSize: 14)),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text("ARMATURA INDOSSATA", style: styleLabel),
                    pw.Text(char.armorName.isEmpty ? "-" : char.armorName, style: pw.TextStyle(font: fontBody, fontSize: 12)),
                  ]),
                ]
              )
            ],
          );
        },
      ),
    );

    // --- PAGINA 2: TUTTI I DETTAGLI (BACKGROUND, LEGAMI, ABILITÀ COMPLETE) ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text("DETTAGLI E NOTE", style: pw.TextStyle(font: fontTitle, fontSize: 18))),
            
            // Background
            _buildDetailSection("BACKGROUND", char.backgroundAnswers, fontBold, fontBody, fontItalic),
            pw.SizedBox(height: 15),

            // Legami
            _buildDetailSection("LEGAMI", char.bonds, fontBold, fontBody, fontItalic),
            pw.SizedBox(height: 15),

            // Abilità Complete
            pw.Text("ABILITÀ E PRIVILEGI", style: pw.TextStyle(font: fontBold, fontSize: 12)),
            pw.Divider(height: 5, color: PdfColors.grey400),
            
            if (ancestryData?['features'] != null)
              ...(ancestryData!['features'] as List).map((f) => _buildFeatureRow("Retaggio", f, fontBold, fontBody)),
            if (communityData?['features'] != null)
              ...(communityData!['features'] as List).map((f) => _buildFeatureRow("Comunità", f, fontBold, fontBody)),
            if (classData?['class_features'] != null)
              ...(classData!['class_features'] as List).map((f) => _buildFeatureRow("Classe", f, fontBold, fontBody)),

            pw.SizedBox(height: 15),
            
            // Inventario Completo
            pw.Text("ZAINO E EQUIPAGGIAMENTO", style: pw.TextStyle(font: fontBold, fontSize: 12)),
            pw.Divider(height: 5, color: PdfColors.grey400),
            pw.Wrap(
              spacing: 10, runSpacing: 10,
              children: char.inventory.map((i) {
                final parts = i.split('|');
                return pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(parts[0], style: pw.TextStyle(font: fontBold, fontSize: 10)),
                      if (parts.length > 1) pw.Text(parts[1], style: pw.TextStyle(font: fontItalic, fontSize: 8, color: PdfColors.grey700)),
                    ]
                  )
                );
              }).toList()
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // --- FUNZIONI DI EXPORT ---
  static Future<void> shareCharacterPdf(Character char) async {
    final pdf = await _generateDocument(char);
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Scheda_${char.name.replaceAll(" ", "_")}.pdf');
  }

  static Future<void> printCharacterPdf(Character char) async {
    final pdf = await _generateDocument(char);
    await Printing.layoutPdf(onLayout: (format) => pdf.save(), name: 'Scheda_${char.name}.pdf');
  }

  // --- HELPER WIDGETS GRAFICI ---

  static pw.Widget _buildUnderlinedField(String label, String value, pw.Font font, double size) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        pw.Container(
          width: double.infinity,
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
          child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: size))
        )
      ]
    );
  }

  static pw.Widget _buildAttributeBox(String label, int value, pw.Font fBold, pw.Font fBody) {
    final skills = _attributeSkills[label] ?? [];
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 35, height: 35,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
              shape: pw.BoxShape.circle
            ),
            child: pw.Text(value >= 0 ? "+$value" : "$value", style: pw.TextStyle(font: fBold, fontSize: 14))
          ),
          pw.SizedBox(width: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: pw.TextStyle(font: fBold, fontSize: 11)),
              pw.SizedBox(height: 2),
              ...skills.map((s) => pw.Text("• $s", style: pw.TextStyle(font: fBody, fontSize: 8, color: PdfColors.grey800))),
            ]
          )
        ]
      )
    );
  }

  static pw.Widget _buildStatBox(String label, String value, String sub, pw.Font fBold, pw.Font fBody, {PdfColor? borderColor}) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: fBold, fontSize: 9)),
        pw.SizedBox(height: 2),
        pw.Container(
          width: 50, height: 40,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor ?? PdfColors.black, width: 1.5),
            borderRadius: pw.BorderRadius.circular(5)
          ),
          child: pw.Text(value, style: pw.TextStyle(font: fBold, fontSize: 18))
        ),
        pw.SizedBox(height: 2),
        pw.Text(sub, style: pw.TextStyle(font: fBody, fontSize: 6, color: PdfColors.grey600)),
      ]
    );
  }

  static pw.Widget _buildTrackerBar(String label, int current, int max, PdfColor color, pw.Font fBold) {
    return pw.Row(
      children: [
        pw.SizedBox(width: 70, child: pw.Text(label, style: pw.TextStyle(font: fBold, fontSize: 9))),
        pw.Expanded(
          child: pw.Wrap(
            spacing: 3,
            children: List.generate(max, (i) => 
              pw.Container(
                width: 10, height: 10,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: i < current ? color : PdfColors.white,
                  border: pw.Border.all(color: PdfColors.black, width: 0.5)
                )
              )
            )
          )
        )
      ]
    );
  }

  static pw.Widget _buildDamageThreshold(String label, String value, pw.Font fBold) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: fBold, fontSize: 7, color: PdfColors.grey700)),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 2),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey), borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Text(value, style: pw.TextStyle(font: fBold, fontSize: 10))
        )
      ]
    );
  }

  static pw.Widget _buildDetailSection(String title, Map<String, String> items, pw.Font fBold, pw.Font fBody, pw.Font fItalic) {
    if (items.isEmpty) return pw.Container();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: fBold, fontSize: 12)),
        pw.Divider(height: 5, color: PdfColors.grey400),
        ...items.entries.map((e) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(e.key, style: pw.TextStyle(font: fBold, fontSize: 10)),
              pw.Text(e.value, style: pw.TextStyle(font: fBody, fontSize: 10)),
            ]
          )
        ))
      ]
    );
  }

  static pw.Widget _buildFeatureRow(String source, dynamic feature, pw.Font fBold, pw.Font fBody) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 60, child: pw.Text("[$source]", style: pw.TextStyle(font: fBold, fontSize: 9, color: PdfColors.grey700))),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(feature['name'] ?? "", style: pw.TextStyle(font: fBold, fontSize: 10)),
                pw.Text(feature['text'] ?? "", style: pw.TextStyle(font: fBody, fontSize: 9)),
              ]
            )
          )
        ]
      )
    );
  }

  // Helper calcolo soglie
  static int _calcMinor(Character c) => (c.classId=='guerriero'||c.classId=='guardiano') ? 7+c.level : 5+c.level;
  static int _calcMajor(Character c) => (c.classId=='guerriero'||c.classId=='guardiano') ? 15+c.level : 13+c.level;
}