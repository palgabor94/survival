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
        'design/popup-concepts-v3/09-fishing-tutorial-B.png',
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
 static const muted=Color(0xFFB0BEAB),leaf=Color(0xFFBBD987);
 Widget txt(String s,double size,{Color color=cream,FontWeight weight=FontWeight.w700})=>Text(s,style:TextStyle(fontSize:size,color:color,fontWeight:weight,height:1.35));
 Widget step(String number,String title,String body)=>Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:24,height:24,alignment:Alignment.center,decoration:BoxDecoration(color:const Color(0xFF36543B),borderRadius:BorderRadius.circular(7)),child:txt(number,12,color:leaf)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[txt(title,13),const SizedBox(height:3),txt(body,11,color:muted,weight:FontWeight.w500)]))]));
 @override Widget build(BuildContext context)=>Scaffold(body:Stack(fit:StackFit.expand,children:[Image.asset('assets/art/camp_tier_0_empty_v1.jpg',fit:BoxFit.cover),const ColoredBox(color:Color(0xBC071D19)),Positioned(top:24,left:22,right:22,child:Row(children:[txt('09 / FISHING TUTORIAL',12,color:gold),const Spacer(),txt('B · FOREST COMPACT',9,color:muted)])),Center(child:Container(width:354,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:const Color(0xFF182F28),borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFF718C64),width:1.5)),child:Column(mainAxisSize:MainAxisSize.min,children:[Container(color:const Color(0xFF213C31),padding:const EdgeInsets.fromLTRB(14,10,8,10),child:Row(children:[const CardArt('basic_rod',size:36),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[txt('HOW TO FISH',19,weight:FontWeight.w900),txt('HOOK · FOLLOW · CATCH',9,color:muted)])),IconButton(onPressed:(){},icon:const Icon(Icons.close_rounded,color:gold),style:IconButton.styleFrom(minimumSize:const Size(44,44)))])),Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 step('1','Wait for a bite','Cast with 1 bait. When the fish bites, tap HOOK.'),
 step('2','Follow the green zone','HOLD moves your white marker right. RELEASE lets it drift left.'),
 Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFF253F32),borderRadius:BorderRadius.circular(9)),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 Row(children:[Container(width:4,height:13,color:cream),const SizedBox(width:6),txt('YOU',9,color:muted),const Spacer(),Container(width:13,height:13,decoration:BoxDecoration(color:leaf,borderRadius:BorderRadius.circular(3))),const SizedBox(width:6),txt('FISH ZONE',9,color:muted)]),const SizedBox(height:13),
 Container(height:38,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:const Color(0xFF10281F),borderRadius:BorderRadius.circular(8)),child:Stack(children:[Positioned(left:100,top:4,bottom:4,width:87,child:Container(decoration:BoxDecoration(color:leaf,borderRadius:BorderRadius.circular(5)))),Positioned(left:142,top:1,bottom:1,width:5,child:Container(decoration:BoxDecoration(color:cream,borderRadius:BorderRadius.circular(3))))])),
 const SizedBox(height:10),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Row(children:[const Icon(Icons.arrow_back_rounded,color:cream,size:16),const SizedBox(width:4),txt('RELEASE',10)]),Row(children:[txt('HOLD',10),const SizedBox(width:4),const Icon(Icons.arrow_forward_rounded,color:cream,size:16)])]),
 const SizedBox(height:16),Row(children:[txt('CATCH PROGRESS',9,color:muted),const Spacer(),txt('62%',9,color:leaf)]),const SizedBox(height:6),ClipRRect(borderRadius:BorderRadius.circular(4),child:const LinearProgressIndicator(value:.62,minHeight:7,color:leaf,backgroundColor:Color(0xFF10281F))),const SizedBox(height:9),txt('Stay in green to fill this bar.',11,color:leaf),
 ])),
 step('3','Fill the catch bar','Alternate holding and releasing to follow the fish until the catch bar fills.'),
 const SizedBox(height:5),Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.info_outline_rounded,size:16,color:gold),const SizedBox(width:8),Expanded(child:txt('Holding all the time will lose the fish. Keep adjusting as the green zone moves.',10,color:muted,weight:FontWeight.w500))]),
 const SizedBox(height:16),Container(height:44,alignment:Alignment.center,decoration:BoxDecoration(color:leaf,borderRadius:BorderRadius.circular(8)),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.touch_app_rounded,size:20,color:ink),const SizedBox(width:8),txt('TRY THE CONTROLS',12,color:ink)])),const SizedBox(height:8),Center(child:txt('Practice freely · No bait or time used',9,color:muted,weight:FontWeight.w500)),
 ]))]))),Positioned(bottom:25,left:24,right:24,child:Text('VISUAL CONTROLS · THREE STEPS · FREE PRACTICE',textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFBDCBB1),fontSize:9,letterSpacing:.5)))]));
}
