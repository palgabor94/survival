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
    for (final light in [false, true]) {
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
        'design/popup-concepts-v3/${light ? '23-card-details-B' : '22-unified-cards-B'}.png',
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
 const Concept({super.key,required this.light});final bool light;
 static const leaf=Color(0xFFBBD987),muted=Color(0xFFB0BEAB);
 Widget t(String s,double n,{Color color=cream,FontWeight weight=FontWeight.w700})=>Text(s,textAlign:TextAlign.left,style:TextStyle(fontSize:n,height:1.25,color:color,fontWeight:weight));
 Widget card(String art,String title,String hint,String status,{bool selected=false,bool locked=false})=>Container(width:112,height:172,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:const Color(0xFF294537),border:Border.all(color:selected?gold:const Color(0xFF718C64),width:2),borderRadius:BorderRadius.circular(10)),child:Column(children:[SizedBox(width:108,height:72,child:Image.asset('assets/art/card_${art}_scene_v1.png',fit:BoxFit.cover)),Padding(padding:const EdgeInsets.symmetric(horizontal:5),child:Column(children:[SizedBox(height:36,child:Center(child:Text(title,textAlign:TextAlign.center,style:const TextStyle(color:cream,fontSize:11,fontWeight:FontWeight.w900,height:1.15)))),SizedBox(height:20,child:Center(child:Text(hint,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:10,height:1.15)))),Container(height:24,alignment:Alignment.center,decoration:BoxDecoration(color:locked?const Color(0xFF5A4031):const Color(0xFF183329),borderRadius:BorderRadius.circular(5)),child:Text(status,textAlign:TextAlign.center,style:TextStyle(color:locked?const Color(0xFFFFB36B):leaf,fontSize:10,fontWeight:FontWeight.w800))),const SizedBox(height:16)]))]));
 Widget deck(List<Widget> cards)=>Row(mainAxisAlignment:MainAxisAlignment.center,children:[for(var i=0;i<cards.length;i++)... [if(i>0)const SizedBox(width:8),cards[i]]]);
 Widget section(String title,String caption,List<Widget> cards)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[t(title,11,color:gold),const Spacer(),t(caption,9,color:muted)])),deck(cards)]);
 Widget resource(String art,String title,String count,bool enough)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[CardArt(art,size:23),const SizedBox(width:9),Expanded(child:t(title,12)),t(count,12,color:enough?leaf:const Color(0xFFFFB36B))]));
 @override Widget build(BuildContext context)=>Scaffold(body:Stack(fit:StackFit.expand,children:[Image.asset('assets/art/camp_tier_0_empty_v1.jpg',fit:BoxFit.cover),const ColoredBox(color:Color(0xDA071D19)),Padding(padding:const EdgeInsets.fromLTRB(19,25,19,24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[t(light?'23 / EXTRA INFORMATION':'22 / ONE CARD SYSTEM',16,color:gold),const SizedBox(height:6),t(light?'Same card. Complete details below.':'112 × 172 · Every screen · Image 3:2',11,color:muted),const SizedBox(height:24),if(!light)...[
 section('CAMP','ACTION / TIME',[card('forage','FORAGE','1 time','SURVIVAL'),card('map','EXPLORE','2 time','TRAVEL'),card('shelter','REST','1 time','SURVIVAL')]),const SizedBox(height:24),
 section('WORKSHOP','SHORT & LONG NAMES',[card('stone_axe','STONE AXE','1 time','READY'),card('camp_tier_2','ESTABLISHED\nCAMP','2 time','MISSING',locked:true),card('emergency_beacon','EMERGENCY\nBEACON','2 time','MISSING',selected:true,locked:true)]),const SizedBox(height:24),
 section('ENCOUNTER','REQUIREMENTS / RISK',[card('torch','USE TORCH','Torch ×1','SAFE'),card('stone_spear','USE SPEAR','Spear required','LOCKED',locked:true),card('trail','RISK THE\nTRAIL','Risk of injury','RISKY')]),const SizedBox(height:22),t('One fixed image, two-line title slot, one short info line and one status band.',12),const SizedBox(height:8),t('Full costs and conditions open below the selected card. No hidden text or oversized cards.',11,color:muted),
 ]else...[
 section('WORKSHOP','SELECTED RECIPE',[card('stone_axe','STONE AXE','1 time','READY'),card('camp_tier_2','ESTABLISHED\nCAMP','2 time','MISSING',locked:true),card('emergency_beacon','EMERGENCY\nBEACON','2 time','MISSING',selected:true,locked:true)]),const SizedBox(height:16),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFF253F32),borderRadius:BorderRadius.circular(10)),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[const CardArt('emergency_beacon',size:30),const SizedBox(width:9),Expanded(child:t('EMERGENCY BEACON',15))]),const SizedBox(height:8),t('Assemble the radio that can call for rescue.',11,color:muted),const SizedBox(height:14),Row(children:[t('MATERIALS',9,color:muted),const Spacer(),t('HAVE / NEED',9,color:muted)]),resource('metal_scrap','Metal Scrap','3 / 2',true),resource('battery','Battery','1 / 1',true),resource('wire','Wire','1 / 1',true),resource('metal_parts','Metal Parts','1 / 1',true),resource('radio_module','Radio Module','1 / 1',true),resource('beacon_core','Beacon Core','0 / 1',false),const Divider(color:Color(0xFF526447),height:16),Row(children:[const Icon(Icons.check_circle_outline,color:leaf,size:17),const SizedBox(width:7),t('Rescue Base required',11,color:muted)]),const SizedBox(height:14),Container(height:44,alignment:Alignment.center,decoration:BoxDecoration(color:const Color(0xFF3E5040),borderRadius:BorderRadius.circular(7)),child:t('BEACON CORE MISSING · 2 TIME',11,color:muted))])),const SizedBox(height:15),t('Even six materials and a camp requirement do not change the card dimensions.',11,color:muted)
 ]]))]));
}
