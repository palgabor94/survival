import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import '../../screenshots/tools/capture_fonts.dart';

const ink = Color(0xFF203B31);
const parchment = Color(0xFFE8DDC0);
const gold = Color(0xFFF0C773);
const cream = Color(0xFFFFF0CC);

Future<void> main() async {
  final keepAlive = Timer.periodic(const Duration(milliseconds: 100), (_) {});
  final binding = LiveTestWidgetsFlutterBinding();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
  await benchmarkWidgets((tester) async {
    await tester.runAsync(loadCaptureFonts);
    await binding.setSurfaceSize(const Size(390, 844));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    for (final light in [false]) {
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: canopyTheme,
            home: Concept(light: light),
          ),
        ),
      );
      await tester.pump();
      final pictures = find
          .byType(Image)
          .evaluate()
          .map((e) => (e.widget as Image).image)
          .toSet();
      final context = tester.element(find.byType(Scaffold));
      var ready = false;
      final loading = Future.wait(
        pictures.map((p) => precacheImage(p, context)),
      ).then((_) => ready = true);
      for (var i = 0; i < 300 && !ready; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      if (!ready) throw StateError('Assets did not load');
      await loading;
      await tester.pumpAndSettle();
      final error = tester.takeException();
      if (error != null) throw StateError('$error');
      final shot =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 3);
      final data = await shot.toByteData(format: ui.ImageByteFormat.png);
      File(
        'design/popup-concepts-v3/07-journal-B.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      shot.dispose();
      stdout.writeln('CAPTURED ${light ? 'A' : 'B'}');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
}

class Concept extends StatelessWidget {
  const Concept({super.key, required this.light});
  final bool light;
  static const muted = Color(0xFFB0BEAB);
  static const leaf = Color(0xFFBBD987);
  Widget text(String s, double size, {Color color = cream, FontWeight weight = FontWeight.w700}) => Text(s, style: TextStyle(fontSize:size,color:color,fontWeight:weight,height:1.3));
  Widget panel(Widget child) => Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFF253F32),borderRadius:BorderRadius.circular(9)),child:child);
  Widget step(String label, String status, bool done, {bool active=false}) => SizedBox(height:36,child:Row(children:[Icon(done?Icons.check_circle_rounded:active?Icons.radio_button_checked:Icons.radio_button_unchecked,size:18,color:done?leaf:active?gold:muted),const SizedBox(width:9),Expanded(child:text(label,12,color:active?cream:muted)),text(status,9,color:active?gold:muted)]));
  Widget entry(String art,String title,String body,String time) => Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[CardArt(art,size:28),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:text(title,12)),text(time,9,color:muted)]),const SizedBox(height:4),text(body,11,color:muted,weight:FontWeight.w500)]))]));
  @override
  Widget build(BuildContext context)=>Scaffold(body:Stack(fit:StackFit.expand,children:[
    Image.asset('assets/art/camp_tier_0_empty_v1.jpg',fit:BoxFit.cover),const ColoredBox(color:Color(0xBC071D19)),
    Positioned(top:24,left:22,right:22,child:Row(children:[text('07 / SURVIVAL JOURNAL',12,color:gold),const Spacer(),text('B · FOREST COMPACT',9,color:muted)])),
    Center(child:Container(width:354,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:const Color(0xFF182F28),borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFF718C64),width:1.5)),child:Column(mainAxisSize:MainAxisSize.min,children:[
      Container(color:const Color(0xFF213C31),padding:const EdgeInsets.fromLTRB(14,10,8,10),child:Row(children:[const CardArt('journal',size:36),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[text('SURVIVAL JOURNAL',17,weight:FontWeight.w900),text('DAY 4 · BASIC REFUGE',9,color:muted)])),IconButton(onPressed:(){},icon:const Icon(Icons.close_rounded,color:gold),style:IconButton.styleFrom(minimumSize:const Size(44,44)))])),
      Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        text('CURRENT OBJECTIVE',9,color:muted),const SizedBox(height:8),
        panel(Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[const CardArt('shelter',size:32),const SizedBox(width:10),Expanded(child:text('Build Established Camp',14))]),const SizedBox(height:9),text('A stronger shelter brings you closer to rescue.',11,color:muted,weight:FontWeight.w500),const SizedBox(height:12),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[resource('wood','10 / 12',false),resource('hardwood','4 / 4',true),resource('fiber','8 / 8',true)]),const SizedBox(height:12),Container(height:44,alignment:Alignment.center,decoration:BoxDecoration(color:leaf,borderRadius:BorderRadius.circular(8)),child:text('VIEW CAMP UPGRADES',11,color:ink))])),
        const SizedBox(height:16),text('PATH TO RESCUE',9,color:muted),const SizedBox(height:8),
        panel(Column(children:[step('Build Basic Refuge','DONE',true),step('Upgrade your camp','CURRENT',false,active:true),step('Recover the rescue parts','LATER',false),step('Send the signal & survive','LATER',false)])),
        const SizedBox(height:16),Row(children:[text('RECENT EVENTS',9,color:muted),const Spacer(),text('LATEST FIRST',9,color:muted)]),const SizedBox(height:4),
        entry('forage','Familiar berries','You gathered food and fibers from a safe patch.','DAY 4'),
        const Divider(height:1,color:Color(0xFF3C5540)),
        entry('shelter','Basic Refuge built','You now have shelter for the night.','DAY 3'),
        const Divider(height:1,color:Color(0xFF3C5540)),
        entry('wood','Fallen timber','Your axe helped you gather more wood.','DAY 3'),
      ]))
    ]))),
    Positioned(bottom:25,left:24,right:24,child:Text('CURRENT GOAL · RESCUE PROGRESS · RECENT HISTORY',textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFBDCBB1),fontSize:9,letterSpacing:.5)))
  ]));
  Widget resource(String art,String amount,bool enough)=>Row(children:[CardArt(art,size:22),const SizedBox(width:5),text(amount,11,color:enough?leaf:Color(0xFFFFB36B))]);
}
