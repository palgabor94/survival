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
        'design/popup-concepts-v3/08-guide-B.png',
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
 const Concept({super.key,required this.light}); final bool light;
 static const muted=Color(0xFFB0BEAB), leaf=Color(0xFFBBD987);
 Widget txt(String s,double size,{Color color=cream,FontWeight weight=FontWeight.w700})=>Text(s,style:TextStyle(fontSize:size,color:color,fontWeight:weight,height:1.35));
 Widget box(Widget child)=>Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:const Color(0xFF253F32),borderRadius:BorderRadius.circular(9)),child:child);
 Widget tip(String art,String title,String body)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[CardArt(art,size:28),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[txt(title,12),const SizedBox(height:3),txt(body,10,color:muted,weight:FontWeight.w500)]))]));
 Widget tutorial(String art,String title,String body)=>SizedBox(height:44,child:Row(children:[CardArt(art,size:28),const SizedBox(width:10),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[txt(title,12),txt(body,10,color:muted,weight:FontWeight.w500)])),const Icon(Icons.chevron_right_rounded,color:gold,size:20)]));
 Widget divider()=>const Divider(height:1,color:Color(0xFF3C5540));
 @override Widget build(BuildContext context)=>Scaffold(body:Stack(fit:StackFit.expand,children:[Image.asset('assets/art/camp_tier_0_empty_v1.jpg',fit:BoxFit.cover),const ColoredBox(color:Color(0xBC071D19)),Positioned(top:24,left:22,right:22,child:Row(children:[txt('08 / SURVIVAL GUIDE',12,color:gold),const Spacer(),txt('B · FOREST COMPACT',9,color:muted)])),Center(child:Container(width:354,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:const Color(0xFF182F28),borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFF718C64),width:1.5)),child:Column(mainAxisSize:MainAxisSize.min,children:[Container(color:const Color(0xFF213C31),padding:const EdgeInsets.fromLTRB(14,10,8,10),child:Row(children:[const CardArt('journal',size:36),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[txt('HOW TO SURVIVE',18,weight:FontWeight.w900),txt('MAKE DAYLIGHT COUNT',9,color:muted)])),IconButton(onPressed:(){},icon:const Icon(Icons.close_rounded,color:gold),style:IconButton.styleFrom(minimumSize:const Size(44,44)))])),Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 box(Row(children:[const Icon(Icons.touch_app_rounded,color:leaf,size:26),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[txt('Time moves when you decide',12),txt('Take your time. Your run saves automatically.',10,color:muted,weight:FontWeight.w500)]))])),
 const SizedBox(height:12),txt('THE BASICS',9,color:muted),const SizedBox(height:4),
 tip('sun','6 time each day','Forage 1 · Explore 2 · Rest 1. Each time spent uses 4 water and 3 food.'),divider(),
 tip('water','Keep your supplies stocked','Empty water or food damages your health. Zero health ends the run.'),divider(),
 tip('craft','Build tools and shelter','CRAFT makes equipment. CAMP upgrades improve sleep and unlock new places.'),divider(),
 tip('moon','Prepare before nightfall','Resolve the night event, then sleep. Keep food and water for the night.'),
 const SizedBox(height:12),txt('LEARN THE MINIGAMES',9,color:muted),const SizedBox(height:8),
 box(Column(children:[tutorial('basic_rod','Fishing','Hook the bite, then hold and release.'),divider(),tutorial('stone_axe','Wood chopping','Learn the timing and tool durability.'),divider(),tutorial('herb','Plant gathering','Learn how to collect useful plants.'),divider(),tutorial('stone_spear','Hunting','Learn how to track and strike.'),divider(),tutorial('stone','Ancient Ruins','Learn the stone-disc controls.')])),
 const SizedBox(height:12),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.info_outline_rounded,size:16,color:gold),const SizedBox(width:8),Expanded(child:txt('Choices reveal their results afterward. Low sanity makes risky decisions less reliable.',10,color:muted,weight:FontWeight.w500))])
]))]))),Positioned(bottom:25,left:24,right:24,child:Text('SHORT SURVIVAL BASICS · TUTORIALS WHEN YOU NEED THEM',textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFBDCBB1),fontSize:9,letterSpacing:.5)))]));
}
