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
    for (final mode in List.generate(concepts.length, (i) => i)) {
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: canopyTheme,
            home: Concept(mode: mode),
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
        'design/popup-concepts-v3/${concepts[mode].file}.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      shot.dispose();
      stdout.writeln('CAPTURED ${concepts[mode].file}');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }, mayRunWithAsserts: true);
  keepAlive.cancel();
  exit(0);
}


class Spec {
 const Spec(this.file,this.title,this.subtitle,this.art,this.kind);
 final String file,title,subtitle,art,kind;
}
const concepts=[
 Spec('10-chopping-tutorial-B','WOOD CHOPPING','THREE STRIKES · FIND YOUR RHYTHM','stone_axe','chop'),
 Spec('11-plants-tutorial-B','PLANT GATHERING','CHOOSE CAREFULLY','herb','plants'),
 Spec('12-hunting-tutorial-B','HOW TO HUNT','ONE THROW · MAKE IT COUNT','stone_spear','hunt'),
 Spec('13-ruins-tutorial-B','THE STONE SEAL','OBSERVE · ROTATE · MATCH','stone','ruins'),
 Spec('14-scene-info-B','BAMBOO GROVE','LOCATION NOTES','map','scene'),
 Spec('15-new-run-confirm-B','START A NEW RUN?','YOUR CURRENT RUN WILL BE REPLACED','journal','confirm'),
 Spec('16-night-summary-B','A NEW DAWN','DAY 5 · NIGHT SUMMARY','sun','night'),
 Spec('17-defeat-B','YOUR JOURNEY ENDS','DAY 7 · HEALTH REACHED ZERO','health','defeat'),
 Spec('18-rescued-B','YOU ARE RESCUED','DAY 14 · SIGNAL RECEIVED','emergency_beacon','rescue'),
 Spec('19-gather-menu-B','GATHER AROUND CAMP','CHOOSE AN ACTIVITY','forage','gather'),
 Spec('20-paused-B','PAUSED','THE ATTEMPT IS FROZEN','journal','pause'),
 Spec('21-leave-attempt-B','LEAVE THIS ATTEMPT?','YOUR TIME HAS ALREADY BEEN SPENT','back','leave'),
];
class Concept extends StatelessWidget {
 const Concept({super.key,required this.mode}); final int mode;
 Spec get spec=>concepts[mode];
 static const muted=Color(0xFFB0BEAB),leaf=Color(0xFFBBD987),orange=Color(0xFFFFB36B);
 Widget txt(String s,double size,{Color color=cream,FontWeight weight=FontWeight.w700})=>Text(s,style:TextStyle(fontSize:size,color:color,fontWeight:weight,height:1.35));
 Widget gap([double h=12])=>SizedBox(height:h);
 Widget box(Widget child)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFF253F32),borderRadius:BorderRadius.circular(9)),child:child);
 Widget button(String title,{bool secondary=false,bool danger=false})=>Container(height:46,alignment:Alignment.center,decoration:BoxDecoration(color:secondary?const Color(0xFF253F32):danger?const Color(0xFF654936):leaf,border:secondary?Border.all(color:const Color(0xFF718C64)):null,borderRadius:BorderRadius.circular(8)),child:txt(title,12,color:secondary?cream:danger?cream:ink));
 Widget note(String title,String body)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[txt(title,13),gap(4),txt(body,11,color:muted,weight:FontWeight.w500)]);
 Widget step(String n,String title,String body)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:24,height:24,alignment:Alignment.center,decoration:BoxDecoration(color:const Color(0xFF36543B),borderRadius:BorderRadius.circular(7)),child:txt(n,12,color:leaf)),const SizedBox(width:10),Expanded(child:note(title,body))]));
 Widget row(String art,String title,String detail,{String? value,Color color=cream})=>Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Row(children:[CardArt(art,size:28),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[txt(title,12),if(detail.isNotEmpty)txt(detail,10,color:muted,weight:FontWeight.w500)])),if(value!=null)txt(value,12,color:color)]));
 Widget timing(bool hunt)=>box(Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[txt('MOVING MARKER',9,color:muted),const Spacer(),txt('AIM FOR THE CENTER',9,color:gold)]),gap(),Container(height:38,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:const Color(0xFF10281F),borderRadius:BorderRadius.circular(8)),child:Stack(children:[Positioned(left:92,top:4,bottom:4,width:106,child:Container(decoration:BoxDecoration(color:leaf.withValues(alpha:.55),borderRadius:BorderRadius.circular(5)))),Positioned(left:127,top:4,bottom:4,width:35,child:Container(color:gold)),Positioned(left:140,top:1,bottom:1,width:5,child:Container(color:cream))])),gap(8),Row(children:[txt('GREEN = GOOD',9,color:leaf),const Spacer(),txt('GOLD = PERFECT',9,color:gold)]),gap(14),button(hunt?'THROW':'CHOP'),gap(7),txt(hunt?'One timed throw. Wait for your opening.':'Three timed strikes. The marker moves back and forth.',10,color:muted,weight:FontWeight.w500)]));
 Widget tutorial(String kind){
 if(kind=='chop'||kind=='hunt')return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[step('1',kind=='chop'?'Bring a working axe':'Bring a working spear','Check your tool in the workshop before starting.'),step('2','Watch the marker','Tap when the white marker reaches the green zone. The gold center is the best timing.'),timing(kind=='hunt'),gap(8),step('3',kind=='chop'?'Complete three strikes':'Make one precise throw',kind=='chop'?'You have 12 seconds. Each strike counts toward the attempt.':'You have 12 seconds to choose your moment.'),gap(8),box(note('Your tool wears with use','Repair worn equipment in the workshop. The result appears after the attempt.')),gap(14),button('GOT IT')]);
 if(kind=='plants')return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[step('1','Look before you pick','You have 8 seconds to choose up to 3 different plants.'),step('2','Check your equipment','Herbs and mushrooms need a knife. Unknown plants need a machete.'),box(Column(children:[row('forage','Berries','Can be picked by hand',value:'AVAILABLE',color:leaf),row('fiber','Fiber','Can be picked by hand',value:'AVAILABLE',color:leaf),row('herb','Herbs','Stone Knife or Machete',value:'TOOL',color:gold)])),gap(8),step('3','Finish your selection','End the attempt when ready, or let the timer run out.'),gap(8),box(note('Unknown plants carry risk','Mushrooms and unfamiliar plants may be unsafe. You discover the result after gathering.')),gap(14),button('GOT IT')]);
 return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[step('1','Read the carved pattern','Look at the symbols on the seal. They show the order to match.'),box(Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[disc(Icons.wb_sunny_outlined,'SUN'),disc(Icons.water_rounded,'WATER'),disc(Icons.eco_outlined,'LEAF')])),gap(),step('2','Rotate each stone disc','Tap a disc to cycle its symbol. Match the pattern above it.'),step('3','Check the seal','Tap ALIGN to test the seal. Each attempt uses 1 daylight.'),gap(),box(note('Observe the scene for the solution','This diagram explains the controls. The carved pattern in the ruins is your reference.')),gap(14),button('GOT IT')]);
 }
 Widget disc(IconData icon,String label)=>Column(children:[Container(width:60,height:60,decoration:BoxDecoration(color:const Color(0xFF58634F),shape:BoxShape.circle,border:Border.all(color:const Color(0xFF879078),width:2)),child:Icon(icon,color:cream,size:30)),gap(6),txt(label,9,color:muted)]);
 Widget body(){switch(spec.kind){
 case 'chop':case 'hunt':case 'plants':case 'ruins':return tutorial(spec.kind);
 case 'scene':return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[note('A dense stand of bamboo','A place to explore for camp materials. Prepare your supplies before heading deeper.'),gap(16),box(Column(children:[row('sun','Journey','Travel uses daylight and supplies',value:'2 TIME',color:gold),row('stone_axe','Useful equipment','Bring working tools for encounters'),row('health','Increasing danger','Pushing deeper raises the risk')])),gap(16),note('Your expedition choices','Return to camp to secure carried loot, or continue while you have enough daylight.'),gap(),box(note('Outcomes stay uncertain','Cards show requirements. Finds and consequences are revealed after your choice.'))]);
 case 'confirm':return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[box(note('This replaces your saved progress','Your camp, equipment and current journey will be reset. This cannot be undone.')),gap(18),button('KEEP PLAYING'),gap(10),button('START NEW RUN',secondary:true)]);
 case 'leave':return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[note('Return to camp now?','Leaving ends this attempt. The time already used will not be refunded.'),gap(14),box(note('Finish when you can','Your final outcome depends on the activity and what you completed before leaving.')),gap(18),button('RESUME ATTEMPT'),gap(10),button('LEAVE ATTEMPT',secondary:true)]);
 case 'pause':return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[note('Take your time','The timer and marker are stopped. Resume when you are ready.'),gap(18),button('RESUME'),gap(10),button('LEAVE ATTEMPT',secondary:true)]);
 case 'gather':return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[txt('ACTIVITIES',9,color:muted),gap(8),box(Column(children:[row('stone_axe','Wood chopping','Three strikes · Axe required',value:'›',color:gold),const Divider(height:1,color:Color(0xFF3C5540)),row('herb','Plant gathering','Pick up to 3 plants',value:'›',color:gold),const Divider(height:1,color:Color(0xFF3C5540)),row('stone_spear','Hunting','One timed throw · Spear required',value:'›',color:gold)])),gap(14),txt('Equipment and time requirements appear before you start. Results are shown afterward.',11,color:muted,weight:FontWeight.w500)]);
 case 'night':return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[note('You made it through the night','Your shelter kept you safe. Daylight has returned.'),gap(14),txt('OVERNIGHT CHANGES',9,color:muted),gap(8),box(Column(children:[row('water','Water','58 → 48',value:'−10',color:orange),row('food','Food','64 → 56',value:'−8',color:orange),row('health','Health','82 → 92',value:'+10',color:leaf),row('sanity','Sanity','74 → 71',value:'−3',color:orange)])),gap(14),box(row('sun','A new day begins','Plan your next steps',value:'6/6 TIME',color:gold)),gap(16),button('BEGIN DAY 5')]);
 case 'defeat':return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Icon(Icons.heart_broken_rounded,size:60,color:orange),gap(12),note('The jungle took its toll','You ran out of water. Your remaining health could not carry you through.'),gap(16),box(Column(children:[row('sun','Days survived','',value:'7'),row('shelter','Camp reached','',value:'BASIC REFUGE'),row('emergency_beacon','Rescue parts found','',value:'1/5')])),gap(14),box(note('For your next journey','Watch your water before exploring. Keep enough supplies for the night.')),gap(18),button('START A NEW RUN')]);
 default:return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Icon(Icons.check_circle_outline_rounded,size:60,color:leaf),gap(12),note('The signal reached them','You built the beacon and kept it alive through the final storm. Help has arrived.'),gap(16),box(Column(children:[row('sun','Days survived','',value:'14'),row('shelter','Camp reached','',value:'RESCUE BASE'),row('emergency_beacon','Final storm','',value:'SURVIVED',color:leaf)])),gap(14),txt('Your journey is complete.',12,color:leaf),gap(18),button('VIEW JOURNAL'),gap(10),button('START A NEW RUN',secondary:true)]);
 }}
 @override Widget build(BuildContext context)=>Scaffold(body:Stack(fit:StackFit.expand,children:[Image.asset('assets/art/camp_tier_0_empty_v1.jpg',fit:BoxFit.cover),const ColoredBox(color:Color(0xBC071D19)),Positioned(top:24,left:22,right:22,child:Row(children:[txt('${spec.file.substring(0,2)} / POPUP CONCEPT',12,color:gold),const Spacer(),txt('B · FOREST COMPACT',9,color:muted)])),Center(child:Container(width:354,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(color:const Color(0xFF182F28),borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFF718C64),width:1.5)),child:Column(mainAxisSize:MainAxisSize.min,children:[Container(color:const Color(0xFF213C31),padding:const EdgeInsets.fromLTRB(14,10,8,10),child:Row(children:[CardArt(spec.art,size:36),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[txt(spec.title,17,weight:FontWeight.w900),txt(spec.subtitle,8,color:muted)])),IconButton(onPressed:(){},icon:const Icon(Icons.close_rounded,color:gold),style:IconButton.styleFrom(minimumSize:const Size(44,44)))])),Padding(padding:const EdgeInsets.all(14),child:body())]))),Positioned(bottom:25,left:24,right:24,child:Text('FOREST COMPACT · CONSISTENT PANELS & CONTROLS',textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFBDCBB1),fontSize:9,letterSpacing:.5)))]));
}
