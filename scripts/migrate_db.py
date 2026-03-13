#!/usr/bin/env python3
"""Full DB migration via Supabase REST API (PostgREST).
Deletes old data, inserts 31 units + all questions for V0.4 structure.
"""

import json
import urllib.request
import urllib.error

ANON_KEY = "sb_publishable_gG_LALbHEJ_Fqsfj3AE39Q_NNdB_n6W"
BASE = "https://dwzzvxjycdbgzrjtjzsr.supabase.co/rest/v1"

HEADERS = {
    "apikey": ANON_KEY,
    "Authorization": f"Bearer {ANON_KEY}",
    "Content-Type": "application/json",
}


def rest_delete(table: str, filter_param: str):
    url = f"{BASE}/{table}?{filter_param}"
    req = urllib.request.Request(url, method="DELETE", headers=HEADERS)
    req.add_header("Prefer", "return=minimal")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        body = e.read()
        raise Exception(f"DELETE {table} failed {e.code}: {body[:300]}")


def rest_insert(table: str, rows: list):
    url = f"{BASE}/{table}"
    data = json.dumps(rows).encode()
    req = urllib.request.Request(url, data=data, method="POST", headers=HEADERS)
    req.add_header("Prefer", "return=minimal")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        body = e.read()
        raise Exception(f"INSERT {table} failed {e.code}: {body[:500]}")


def rest_count(table: str) -> int:
    url = f"{BASE}/{table}?select=id"
    req = urllib.request.Request(url, headers=HEADERS)
    req.add_header("Prefer", "count=exact")
    with urllib.request.urlopen(req) as resp:
        cr = resp.headers.get("Content-Range", "0/0")
        return int(cr.split("/")[-1]) if "/" in cr else 0


# ── UNITS ──────────────────────────────────────────────────────────────────────

UNITS = [
    # (id, belt, order_index, title, description, tags, is_belt_test, coach_intro,
    #  kind, section_title, topic_title, lesson_index, lesson_total, char_name, char_msg)
    ("wb-01-l1","white",0,"Closed Guard Control","Control and break posture",["guard"],False,
     "Closed guard is your first weapon. Pull their head down, keep your knees tight.",
     "lesson","Guard Game","Closed Guard Control",1,2,None,None),
    ("wb-01-l2","white",1,"Closed Guard Control","Control and break posture",["guard"],False,None,
     "lesson",None,"Closed Guard Control",2,2,None,None),
    ("wb-02-l1","white",2,"Closed Guard Attacks","Sweeps and submissions",["guard","sweeps"],False,
     "Attacks flow from a broken posture. Triangle, armbar, hip bump — they all start the same way.",
     "lesson",None,"Closed Guard Attacks",1,2,None,None),
    ("wb-02-l2","white",3,"Closed Guard Attacks","Sweeps and submissions",["guard","sweeps"],False,None,
     "lesson",None,"Closed Guard Attacks",2,2,None,None),
    ("wb-cm-01","white",4,"Marco","",[],False,None,
     "characterMoment",None,None,None,None,
     "marco","Closed guard is a system, not just a position. You're not waiting — you're hunting. Every second they're in your guard, you're looking for the break."),
    ("wb-03-l1","white",5,"Guard Passing","Break and pass the closed guard",["guard","passing"],False,
     "Passing guard requires patience. Keep elbows tight, control their hips.",
     "lesson",None,"Guard Passing",1,2,None,None),
    ("wb-03-l2","white",6,"Guard Passing","Break and pass the closed guard",["guard","passing"],False,None,
     "lesson",None,"Guard Passing",2,2,None,None),
    ("wb-mr-gg","white",7,"Guard Game Review","Mixed questions from all guard topics",["guard"],False,None,
     "mixedReview",None,None,None,None,None,None),
    ("wb-me-gg","white",8,"Guard Game Exam","Prove your guard game",["guard"],False,None,
     "miniExam",None,None,None,None,None,None),
    ("wb-04-l1","white",9,"Side Control Top","Maintain and dominate",["side control"],False,
     "Side control is all about weight and angles. Hips low, cross-face on.",
     "lesson","Top Game","Side Control Top",1,2,None,None),
    ("wb-04-l2","white",10,"Side Control Top","Maintain and dominate",["side control"],False,None,
     "lesson",None,"Side Control Top",2,2,None,None),
    ("wb-05-l1","white",11,"Side Control Escape","Recover guard",["side control","escapes"],False,
     "Escaping side control starts with frames — create space before you move.",
     "lesson",None,"Side Control Escape",1,2,None,None),
    ("wb-05-l2","white",12,"Side Control Escape","Recover guard",["side control","escapes"],False,None,
     "lesson",None,"Side Control Escape",2,2,None,None),
    ("wb-cm-02","white",13,"Old Chen","",[],False,None,
     "characterMoment",None,None,None,None,
     "oldChen","You moved before you were ready. The escape starts earlier than you think."),
    ("wb-06-l1","white",14,"Mount Control","Maintain and advance from mount",["mount"],False,
     "Mount is your highest value position. Low hips, cross-face, follow their escapes.",
     "lesson",None,"Mount Control",1,2,None,None),
    ("wb-06-l2","white",15,"Mount Control","Maintain and advance from mount",["mount"],False,None,
     "lesson",None,"Mount Control",2,2,None,None),
    ("wb-07-l1","white",16,"Mount Escape","Escape from the bottom of mount",["mount","escapes"],False,
     "Two tools: upa (bridge and roll) and elbow-knee. Learn which to use when.",
     "lesson",None,"Mount Escape",1,2,None,None),
    ("wb-07-l2","white",17,"Mount Escape","Escape from the bottom of mount",["mount","escapes"],False,None,
     "lesson",None,"Mount Escape",2,2,None,None),
    ("wb-cm-03","white",18,"Rex","",[],False,None,
     "characterMoment",None,None,None,None,
     "rex","Okay okay okay — mount escape is the one where I keep trying to muscle out and Marco keeps sighing at me. But you? You actually got it. BRO."),
    ("wb-mr-tg","white",19,"Top Game Review","Mixed questions from top game topics",[],False,None,
     "mixedReview",None,None,None,None,None,None),
    ("wb-me-tg","white",20,"Top Game Exam","Prove your top game",[],False,None,
     "miniExam",None,None,None,None,None,None),
    ("wb-08-l1","white",21,"Back Control","Take and keep the back",["back control"],False,
     "The back is the most dominant position. Hooks inside, seatbelt tight.",
     "lesson","Back & Submissions","Back Control",1,2,None,None),
    ("wb-08-l2","white",22,"Back Control","Take and keep the back",["back control"],False,None,
     "lesson",None,"Back Control",2,2,None,None),
    ("wb-09-l1","white",23,"Submissions","Basic submissions",["submissions"],False,
     "Submissions only work from controlled positions. Position first, then submission.",
     "lesson",None,"Submissions",1,2,None,None),
    ("wb-09-l2","white",24,"Submissions","Basic submissions",["submissions"],False,None,
     "lesson",None,"Submissions",2,2,None,None),
    ("wb-cm-04","white",25,"Old Chen","",[],False,None,
     "characterMoment",None,None,None,None,
     "oldChen","The submission is the punctuation. The sentence is the position. Learn to write the sentence."),
    ("wb-10-l1","white",26,"Takedowns","Get the fight to the ground",["takedowns"],False,
     "Two shots to learn first: double-leg and single-leg. Level change, penetration step, drive through.",
     "lesson",None,"Takedowns",1,2,None,None),
    ("wb-10-l2","white",27,"Takedowns","Get the fight to the ground",["takedowns"],False,None,
     "lesson",None,"Takedowns",2,2,None,None),
    ("wb-mr-bs","white",28,"Back & Submissions Review","",[],False,None,
     "mixedReview",None,None,None,None,None,None),
    ("wb-me-bs","white",29,"Back & Submissions Exam","",[],False,None,
     "miniExam",None,None,None,None,None,None),
    ("wb-bt1","white",30,"Stripe 1 Test","Prove your White Belt foundations",[],True,None,
     "beltTest","Belt Test",None,None,None,None,None),
]


def build_unit_dicts() -> list:
    rows = []
    for u in UNITS:
        (uid, belt, oi, title, desc, tags, is_bt, coach,
         kind, sec_title, top_title, l_idx, l_tot, c_name, c_msg) = u
        rows.append({
            "id": uid,
            "belt": belt,
            "order_index": oi,
            "title": title,
            "description": desc,
            "tags": tags,
            "is_belt_test": is_bt,
            "coach_intro": coach,
            "kind": kind,
            "section_title": sec_title,
            "topic_title": top_title,
            "lesson_index": l_idx,
            "lesson_total": l_tot,
            "character_name": c_name,
            "character_message": c_msg,
        })
    return rows


# ── QUESTIONS ──────────────────────────────────────────────────────────────────

QUESTION_DATA = {
    "q-cg-01": ("mcq2","Your opponent tries to stand up from your closed guard. What should you do?",["Break their posture down","Open guard immediately"],"Break their posture down","Pull them forward to break posture before they base out and pass.",["guard"],1,"If they stand with your guard closed you risk a stack pass — break posture first."),
    "q-cg-02": ("mcq4","Which grip best breaks your opponent's posture in closed guard?",["Collar and sleeve","Double collar","Double underhooks on head","Wrist control"],"Double collar","Double collar grips let you pull the head down and break posture efficiently.",["guard"],2,None),
    "q-cg-03": ("trueFalse","Squeezing your knees together in closed guard gives you more control.",["True","False"],"True","Closed knees remove space for your opponent to posture up.",["guard"],1,None),
    "q-cg-04": ("mcq4","What is the PRIMARY goal of closed guard?",["Defend and stall","Wait for your opponent to tire","Control distance and threaten attacks","Rest your legs"],"Control distance and threaten attacks","Closed guard is an offensive position — break posture, attack submissions, set up sweeps.",["guard"],1,"A passive closed guard gets passed. Stay active — create threats from every position."),
    "q-cg-05": ("trueFalse","You should keep your guard closed when your opponent stands up completely.",["True","False"],"False","Holding closed guard while they stand risks a guard pass. Open and adapt.",["guard"],2,"When they stand, open guard and play open guard or pull them back down."),
    "q-cg-06": ("mcq2","Your opponent posts both hands on your hips to create distance. Best response?",["Pull their elbows in and break posture","Open guard and scoot away"],"Pull their elbows in and break posture","Removing their base by collapsing the elbows shuts down the posture attempt.",["guard"],2,None),
    "q-cg-07": ("fillBlank","Break their ___ before threatening submissions from closed guard.",["posture","hooks","grip","base"],"posture","Without breaking posture, your opponent is too upright to submit.",["guard"],1,"Remember: posture first, then attack. You can't choke someone sitting tall."),
    "q-cg-08": ("trueFalse","In closed guard, your hips should be flat on the mat for best control.",["True","False"],"False","Keeping your hips active and off the mat lets you angle for attacks and break posture.",["guard"],2,None),
    "q-cga-01": ("mcq4","To set up a triangle from closed guard, you must first:",["Open your guard wide","Break posture and isolate one arm outside your legs","Grab their ankle","Stand up"],"Break posture and isolate one arm outside your legs","One arm in, one arm out creates the triangle angle.",["guard","submissions"],2,"Triangle fails when both arms are inside your legs — break posture and push one out."),
    "q-cga-02": ("trueFalse","You can effectively attack with an armbar from closed guard without breaking posture first.",["True","False"],"False","A posted opponent resists the armbar easily. Break posture to remove their base.",["guard","submissions"],2,None),
    "q-cga-03": ("mcq2","Which movement creates the angle needed for a triangle choke from guard?",["Hip escape (shrimp) to the side","Bridging straight up"],"Hip escape (shrimp) to the side","Shrimping creates the angle to swing a leg over the shoulder.",["guard","submissions"],2,None),
    "q-cga-04": ("fillBlank","For the triangle from guard, you must isolate one ___ inside your legs.",["arm","leg","head","shoulder"],"arm","One arm in, one arm out — the classic triangle setup.",["guard","submissions"],1,"Both arms inside? Your triangle is weak. Push one arm across and lock."),
    "q-cga-05": ("mcq4","For the hip bump sweep, you push off your hand and rotate toward which direction?",["Away from your far arm","Straight up","Toward the same side as your posting arm","Back down to the mat"],"Toward the same side as your posting arm","You post with one arm and hip bump into that same side to off-balance them.",["guard","sweeps"],2,None),
    "q-cga-06": ("trueFalse","The scissor sweep works best when your opponent is sitting back in a low base.",["True","False"],"False","Scissor sweep works best when they are upright — a low base resists the sweep.",["guard","sweeps"],2,"Pull them forward first to raise their base before attempting the scissor sweep."),
    "q-cga-07": ("mcq2","What is the key ingredient that opens all submission attacks from closed guard?",["Breaking their posture","Opening your legs wide"],"Breaking their posture","Broken posture creates proximity and removes their base — essential for every guard attack.",["guard"],1,None),
    "q-cga-08": ("fillBlank","The ___ sweep uses one leg to push the hip while pulling the arm to off-balance the opponent.",["scissor","hip bump","tripod","flower"],"scissor","Scissor sweep: one leg cuts the hip, the other pushes the shoulder.",["guard","sweeps"],2,None),
    "q-gp-01": ("mcq4","When passing closed guard from knees, where should your elbows be?",["Wide for balance","On the mat beside you","Tight to their hips","Grabbing their belt"],"Tight to their hips","Tight elbows prevent the opponent from getting underhooks or arm drags.",["guard","passing"],1,"Elbows flared = underhook gift. Keep them glued to their hips."),
    "q-gp-02": ("trueFalse","Standing up is always the safest way to pass closed guard.",["True","False"],"False","Standing can be effective but is risky — sweeps and leg locks become available.",["guard","passing"],2,None),
    "q-gp-03": ("mcq2","Your opponent attempts a hip bump sweep from closed guard. What stops it?",["Post your hand on the mat behind you","Squeeze your knees tighter"],"Post your hand on the mat behind you","A hand post behind you removes the base they need to complete the sweep.",["guard","passing"],2,None),
    "q-gp-04": ("mcq4","Which technique does NOT effectively open closed guard?",["Stand and drive knee to tailbone","Elbow to knee pressure","Grab one ankle and push","Grab their belt and pull up"],"Grab their belt and pull up","Grabbing the belt doesn't create the hip pressure needed to open the guard.",["guard","passing"],2,"Focus on hip pressure downward — not pulling up. That's what opens the guard."),
    "q-gp-05": ("trueFalse","When passing guard, getting one knee free is enough — you don't need to control both hips.",["True","False"],"False","Controlling both hips prevents the guard from re-closing and limits sweep attempts.",["guard","passing"],2,None),
    "q-gp-06": ("mcq2","You are about to complete a guard pass but your opponent grabs your sleeve. Priority?",["Clear the grip before passing","Ignore it and rush the pass"],"Clear the grip before passing","Uncleared grips give your opponent handles to re-guard or sweep mid-pass.",["guard","passing"],3,None),
    "q-gp-07": ("fillBlank","The toreando pass controls both ___ to pin the legs open and walk around.",["ankles","knees","hips","thighs"],"ankles","Gripping both ankles in the toreando lets you redirect the legs and pass around.",["guard","passing"],2,"Don't muscle the toreando — use hip movement and angles, not arm strength."),
    "q-gp-08": ("trueFalse","After passing the guard, you should immediately go for a submission.",["True","False"],"False","Establish and consolidate your position first — secure the pass before attacking.",["guard","passing"],1,None),
    "q-sc-01": ("mcq4","In side control, where should your hips be to apply maximum pressure?",["High and away from opponent","Low and heavy across their torso","Perpendicular at their waist","Stacked on their legs"],"Low and heavy across their torso","Low hips add pressure and make it hard for the opponent to bridge or roll.",["side control"],1,"Think of your hips as your weight anchor — keep them low and heavy across their chest."),
    "q-sc-02": ("trueFalse","Cross-face pressure in side control helps flatten your opponent.",["True","False"],"True","Cross-face turns the head and disconnects the opponent's hip-shoulder alignment.",["side control"],1,None),
    "q-sc-03": ("mcq2","Your opponent tries to escape side control by pushing your head. Best response?",["Swim under their arm for underhook","Back away and re-establish"],"Swim under their arm for underhook","Swimming under creates underhook control and maintains the position.",["side control"],2,None),
    "q-sc-04": ("mcq4","Which submission is most directly available from standard side control?",["Rear naked choke","Heel hook","Kimura on the near arm","Triangle from guard"],"Kimura on the near arm","Kimura is directly available from side control when the opponent's arm is exposed.",["side control","submissions"],2,"The near arm kimura — if they push your hip, give them the kimura."),
    "q-sc-05": ("trueFalse","The 'north-south' position is a variant of side control.",["True","False"],"True","North-south is side control rotated 180° — head near opponent's hips.",["side control"],2,None),
    "q-sc-06": ("mcq2","Your opponent bridges strongly to escape side control. To counter, you should:",["Go with the roll and take mount","Post your leg out and stay flat"],"Go with the roll and take mount","Following the bridge and taking mount is the reward for reading the escape.",["side control"],3,None),
    "q-sc-07": ("fillBlank","Use a ___ to turn your opponent's head away and flatten them in side control.",["cross-face","collar grip","knee shield","underhook"],"cross-face","Cross-face disconnects shoulder and hip alignment, preventing a bridge.",["side control"],1,"No cross-face? They can turn into you easily. Always establish it first."),
    "q-sc-08": ("trueFalse","In side control, distributing your weight on both knees reduces your pressure on the opponent.",["True","False"],"True","To maximize pressure, drive your weight through your chest and hips, not knees.",["side control"],2,None),
    "q-sce-01": ("mcq4","What is the first step to begin escaping from side control?",["Immediately bridge hard","Create frames with your arms against their neck and hip","Grab their leg","Turn away from them"],"Create frames with your arms against their neck and hip","Frames create space and stop your opponent from flattening you completely.",["side control","escapes"],1,"Frames first — without space you can't move. Elbow to hip, forearm to neck."),
    "q-sce-02": ("trueFalse","You should shrimp (hip escape) before establishing frames when escaping side control.",["True","False"],"False","Frames create the space that makes shrimping possible. Frame first, then shrimp.",["side control","escapes"],2,None),
    "q-sce-03": ("mcq2","When shrimping to recover guard from side control, your hips move:",["Away from the opponent (toward their feet)","Toward the opponent's head"],"Away from the opponent (toward their feet)","Shrimping away creates the space to bring your knee inside and re-guard.",["side control","escapes"],2,None),
    "q-sce-04": ("fillBlank","Bridge and ___ to create the space needed to escape side control.",["shrimp","roll","push","sit up"],"shrimp","The bridge-shrimp combination is the fundamental side control escape movement.",["side control","escapes"],1,"Small shrimps beat big ones — precise hip movement beats muscling out."),
    "q-sce-05": ("mcq4","When framing against side control, where does your bottom forearm go?",["Across their throat","On their hip","Under their arm","Against their knee"],"On their hip","Hip frame stops them from advancing while your top arm handles their upper body.",["side control","escapes"],2,None),
    "q-sce-06": ("trueFalse","Turning into your opponent from bottom side control is a valid escape direction.",["True","False"],"True","Turning into them allows you to shoot for a single leg or take the turtle position.",["side control","escapes"],2,"Two options: turn away (re-guard) or turn in (single leg/turtle). Both work."),
    "q-sce-07": ("mcq2","You recover half guard from side control. Your opponent quickly flattens you. You should:",["Use your underhook to fight back to full guard or a sweep","Immediately try to stand up"],"Use your underhook to fight back to full guard or a sweep","Underhook from half guard is the key tool — use it to create movement.",["side control","escapes"],3,None),
    "q-sce-08": ("fillBlank","The ___ escape from side control involves bridging and spinning to face the opponent.",["granby","upa","elbow-knee","sit-out"],"granby","The granby roll uses a bridge and spin to face the opponent or recover guard.",["side control","escapes"],3,None),
    "q-mc-01": ("mcq4","Your opponent bridges (upa) to escape mount. What is the best counter?",["Squeeze your knees tighter","Post your arm out and follow the roll","Lean forward with all weight","Grab their collar"],"Post your arm out and follow the roll","Posting stops the bridge. Following the roll lets you retake mount from the other side.",["mount"],1,"When they bridge, don't resist — post out and flow over. Fighting the bridge tires you out."),
    "q-mc-02": ("trueFalse","High mount (near the armpits) gives you better control than low mount.",["True","False"],"True","High mount limits arm movement and opens more submission opportunities.",["mount"],1,None),
    "q-mc-03": ("trueFalse","Keeping your heels hooked under your opponent's legs in mount makes escape harder.",["True","False"],"True","Hooks under the legs limit bridging power and prevent the elbow-knee escape.",["mount"],2,None),
    "q-mc-04": ("mcq2","Your opponent gets their elbow to their knee and starts shrimping out. You should:",["Follow their hips and re-establish mount","Abandon mount and take side control"],"Follow their hips and re-establish mount","Staying active and following the hips is the key to keeping mount.",["mount"],3,None),
    "q-mc-05": ("mcq4","Which mount detail best prevents your opponent from turning to face you?",["Grabbing their wrists","Grapevining their legs","Cross-face pressure on their neck","Sitting up tall"],"Cross-face pressure on their neck","Cross-face in mount blocks the turn just as in side control — head controls the body.",["mount"],2,"Mount + cross-face = very hard to escape. This is your highest value detail."),
    "q-mc-06": ("trueFalse","Leaning forward in mount transfers more weight onto your opponent and increases pressure.",["True","False"],"True","Leaning forward shifts your center of gravity onto their chest and lungs.",["mount"],1,None),
    "q-mc-07": ("fillBlank","In mount, keep your ___ low to add pressure and make bridging difficult.",["hips","shoulders","knees","elbows"],"hips","Low hips maximize pressure and limit the opponent's ability to bridge.",["mount"],1,"Hips low = heavy mount. Hips high = light mount. Heaviness wins matches."),
    "q-mc-08": ("mcq4","Compared to mount, knee-on-belly is better for:",["Long-term pressure","Preventing all escapes","Mobility and quick transitions","Rear choke setups"],"Mobility and quick transitions","Knee-on-belly is a transitional position — good for transitions but less stable than mount.",["mount"],2,None),
    "q-me-01": ("mcq2","Which mount escape uses a bridge and rotation to roll the top person over?",["Upa escape","Elbow-knee escape"],"Upa escape","Upa uses bridging force and trapping an arm and leg to roll.",["mount","escapes"],1,"Upa works best when they are in low mount. In high mount, use elbow-knee."),
    "q-me-02": ("mcq4","The elbow-knee escape from mount is designed to:",["Submit the opponent with a triangle","Roll them over your head","Recover half guard or full guard","Take their back"],"Recover half guard or full guard","Elbow-knee escape shrimps to create space and re-guard.",["mount","escapes"],2,None),
    "q-me-03": ("mcq4","Before executing the upa escape, you must first:",["Create frames and push them off","Trap their arm and leg on the same side","Sit up and grab their collar","Turn toward them"],"Trap their arm and leg on the same side","Trapping the arm and leg gives you the fulcrum to complete the bridge-and-roll.",["mount","escapes"],2,"No trap = no upa. Their posted arm stops the roll. Trap it first every time."),
    "q-me-04": ("trueFalse","Shrimping creates the space needed to execute the elbow-knee escape from mount.",["True","False"],"True","Shrimping hips to one side creates the gap to insert your knee and recover guard.",["mount","escapes"],1,None),
    "q-me-05": ("mcq2","When should you prefer the upa over the elbow-knee escape?",["When opponent is in low mount with their weight forward","When opponent is in high mount near your armpits"],"When opponent is in low mount with their weight forward","Forward weight makes the bridge more effective. High mount closes off the rolling space.",["mount","escapes"],2,None),
    "q-me-06": ("fillBlank","In the upa escape, trap their ___ before bridging to complete the roll.",["arm and leg","head and neck","hips","belt"],"arm and leg","Trapping arm and leg on the same side is the setup for a successful upa roll.",["mount","escapes"],1,"Same-side trap is the key — arm and leg on the same side, then bridge explosively."),
    "q-me-07": ("mcq4","After bridging in the upa escape, where do you continue to roll?",["Back down to where you started","To the same side as the trapped arm and leg","Straight up","Toward their legs"],"To the same side as the trapped arm and leg","You roll over the trapped side — that's the path of least resistance.",["mount","escapes"],2,None),
    "q-me-08": ("trueFalse","The upa escape becomes harder when your opponent is in high mount near your armpits.",["True","False"],"True","High mount tightens the position and makes bridging and trapping more difficult.",["mount","escapes"],2,None),
    "q-bc-01": ("mcq4","When you have back control, where should your hooks be?",["Behind their knees","On their ankles","Inside their thighs","Outside their hips"],"Inside their thighs","Inside hooks on the thighs keep you attached and limit hip mobility.",["back control"],1,"Inside hooks = control. Outside hooks can be kicked off easily."),
    "q-bc-02": ("trueFalse","You must maintain at least one hook to keep back control.",["True","False"],"True","Losing both hooks lets the opponent escape or roll out of back control.",["back control"],1,None),
    "q-bc-03": ("mcq2","When setting up the rear naked choke, what must you establish first?",["Seatbelt grip (over-under around torso)","Choking arm directly under chin"],"Seatbelt grip (over-under around torso)","Seatbelt control establishes position and prevents the opponent turning.",["back control","submissions"],2,"No seatbelt = they can turn and escape. Seatbelt first, then go for the choke."),
    "q-bc-04": ("mcq4","To escape back control, which direction should you move toward?",["Away from both arms","Toward the choking arm side","Straight forward","Toward the non-choking arm side"],"Toward the choking arm side","Moving toward the choking arm side lets you work to face the opponent.",["back control","escapes"],2,None),
    "q-bc-05": ("trueFalse","A body triangle is a stronger control than two hooks from the back.",["True","False"],"True","The body triangle locks the hips completely and is very hard to escape.",["back control"],2,None),
    "q-bc-06": ("mcq2","Your opponent grabs your choking wrist to defend the RNC. You should:",["Switch to a collar choke or bow-and-arrow","Keep pulling the same arm harder"],"Switch to a collar choke or bow-and-arrow","Switching attacks prevents stalling and exploits their defensive focus.",["back control","submissions"],3,"When they defend the RNC, switch — don't muscle through. Their defense opens another attack."),
    "q-bc-07": ("fillBlank","Keep your back control position by staying ___ to their body like a backpack.",["tight","loose","square","low"],"tight","Staying tight prevents space that allows them to turn or slide out.",["back control"],1,None),
    "q-bc-08": ("trueFalse","From the back, it is safer to have the opponent on their side rather than flat on their back.",["True","False"],"True","On their back they can steer your hooks off — on their side you have more control.",["back control"],2,"Angle matters: on their side gives you better hook control and choke access."),
    "q-sub-01": ("mcq4","When applying an armbar from mount, the correct position is:",["Thumbs down, pull to chest","Both hands on the wrist, push away","Thumbs up, hips thrust up","Wrists crossed, pull down"],"Thumbs up, hips thrust up","Thumb up rotates the elbow into position. Hips thrust apply the extension force.",["submissions"],2,"Thumb up = elbow faces down = armbar works. Thumb down = no torque."),
    "q-sub-02": ("trueFalse","A triangle choke works by compressing the carotid arteries, not the airway.",["True","False"],"True","Blood chokes cut off blood to the brain — faster and more effective than air chokes.",["submissions"],1,None),
    "q-sub-03": ("mcq2","The kimura grip is: one hand on their wrist, the other hand...",["Gripping your own wrist (figure-four)","On their bicep"],"Gripping your own wrist (figure-four)","Kimura = figure-four: wrist with one hand, grip your own wrist with the other.",["submissions"],2,"Figure-four grip is the key — without it you just have a wrist grip, not a kimura."),
    "q-sub-04": ("mcq4","When is it appropriate to tap in training?",["Only when you are about to be knocked out","Only if you have no way to escape","Whenever a submission is applied and you feel it working","Never — tapping is giving up"],"Whenever a submission is applied and you feel it working","Tapping early protects you from injury and is a sign of good training culture.",["submissions"],1,None),
    "q-sub-05": ("trueFalse","The rear naked choke requires you to lock your hands together to be effective.",["True","False"],"False","The RNC uses one arm to choke and the other to push the head — no hand lock needed.",["submissions"],2,"Interlocking hands in RNC is weaker — use the palm-to-bicep squeeze instead."),
    "q-sub-06": ("mcq2","Your opponent clasps their hands to defend your armbar. Best response?",["Break the grip by extending one arm and rotating","Pull both arms toward you simultaneously"],"Break the grip by extending one arm and rotating","Rotating one arm breaks the grip structure more efficiently than pulling straight.",["submissions"],3,None),
    "q-sub-07": ("fillBlank","To finish a triangle choke, pull the head ___ and squeeze your knees together.",["down","sideways","up","back"],"down","Pulling the head down tightens the triangle and increases carotid compression.",["submissions"],2,"Head down + knees squeeze = tap. Missing either makes the triangle loose."),
    "q-sub-08": ("trueFalse","Finishing an armbar requires you to control the opponent's wrist, not just the arm.",["True","False"],"True","Wrist control ensures the elbow stays aligned for maximum extension force.",["submissions"],2,None),
    "q-td-01": ("mcq4","In a single-leg takedown, the key finish movement after securing the leg is:",["Pull straight back","Run the pipe (step outside and cut)","Jump on top","Lift straight up"],"Run the pipe (step outside and cut)","Stepping outside cuts the angle and drops your weight through the leg.",["takedowns"],2,"Drive your shoulder into the thigh and step outside — don't just pull back."),
    "q-td-02": ("trueFalse","In wrestling, a 'sprawl' is used to defend against a double-leg shot.",["True","False"],"True","Sprawling drives your hips back and down to stuff the shot.",["takedowns"],1,None),
    "q-td-03": ("mcq2","The double-leg takedown requires you to:",["Change levels and shoot low","Stay tall and grab both wrists"],"Change levels and shoot low","Level change drops below the opponent's center of gravity for the shot.",["takedowns"],1,"Level change is everything — stay tall and you'll bounce off. Drop low and shoot."),
    "q-td-04": ("mcq4","After a successful takedown, your immediate priority is:",["Go for a submission immediately","Stand back up","Establish top position control","Call for a time-out"],"Establish top position control","Secure position first — rushing submissions from bad position loses them.",["takedowns"],2,None),
    "q-td-05": ("trueFalse","Pulling guard counts as a takedown in competition BJJ.",["True","False"],"False","Pulling guard gives 2 takedown points to the opponent.",["takedowns"],2,"Pulling guard surrenders points — if you want points, fight for the takedown."),
    "q-td-06": ("mcq2","Your opponent has a collar-and-elbow grip. You want to shoot. First:",["Break their grips before shooting","Shoot immediately before they react"],"Break their grips before shooting","Shooting with grips intact lets them sprawl or redirect your momentum.",["takedowns"],3,None),
    "q-td-07": ("fillBlank","A ___ sprawl stops the double-leg shot by driving hips back and down.",["defensive","reactive","front","hip"],"defensive","The defensive sprawl counters the shot by removing your hips from their reach.",["takedowns"],1,"Sprawl early — waiting until they grab your legs is too late."),
    "q-td-08": ("trueFalse","In standup, maintaining inside position on your opponent's arms gives you control.",["True","False"],"True","Inside position prevents their attacks and sets up your own entries.",["takedowns"],2,None),
    # Belt test questions (unique IDs)
    "bt-cg-01": ("mcq4","What is the PRIMARY goal of closed guard?",["Defend and stall","Wait for your opponent to tire","Control distance and threaten attacks","Rest your legs"],"Control distance and threaten attacks","Closed guard is an offensive position.",["guard"],1,None),
    "bt-cg-02": ("trueFalse","Squeezing your knees together in closed guard gives you more control.",["True","False"],"True","Closed knees remove space for your opponent to posture up.",["guard"],1,None),
    "bt-cga-01": ("mcq4","To set up a triangle from closed guard, you must first:",["Open your guard wide","Break posture and isolate one arm outside your legs","Grab their ankle","Stand up"],"Break posture and isolate one arm outside your legs","One arm in, one arm out creates the triangle angle.",["guard","submissions"],2,None),
    "bt-cga-02": ("trueFalse","The scissor sweep works best when your opponent is sitting back in a low base.",["True","False"],"False","Scissor sweep works best when they are upright.",["guard","sweeps"],2,None),
    "bt-gp-01": ("mcq4","When passing closed guard from knees, where should your elbows be?",["Wide for balance","On the mat beside you","Tight to their hips","Grabbing their belt"],"Tight to their hips","Tight elbows prevent underhooks or arm drags.",["guard","passing"],1,None),
    "bt-gp-02": ("trueFalse","After passing the guard, you should immediately go for a submission.",["True","False"],"False","Establish and consolidate your position first.",["guard","passing"],1,None),
    "bt-sc-01": ("mcq4","In side control, where should your hips be to apply maximum pressure?",["High and away from opponent","Low and heavy across their torso","Perpendicular at their waist","Stacked on their legs"],"Low and heavy across their torso","Low hips add pressure.",["side control"],1,None),
    "bt-sc-02": ("trueFalse","Cross-face pressure in side control helps flatten your opponent.",["True","False"],"True","Cross-face turns the head and disconnects the opponent's hip-shoulder alignment.",["side control"],1,None),
    "bt-sce-01": ("mcq4","What is the first step to begin escaping from side control?",["Immediately bridge hard","Create frames with your arms against their neck and hip","Grab their leg","Turn away from them"],"Create frames with your arms against their neck and hip","Frames create space.",["side control","escapes"],1,None),
    "bt-sce-02": ("trueFalse","You should shrimp before establishing frames when escaping side control.",["True","False"],"False","Frames create the space that makes shrimping possible.",["side control","escapes"],2,None),
    "bt-mc-01": ("trueFalse","High mount (near the armpits) gives you better control than low mount.",["True","False"],"True","High mount limits arm movement.",["mount"],1,None),
    "bt-mc-02": ("mcq4","In mount, which detail best prevents your opponent from turning to face you?",["Grabbing their wrists","Grapevining their legs","Cross-face pressure on their neck","Sitting up tall"],"Cross-face pressure on their neck","Cross-face in mount blocks the turn.",["mount"],2,None),
    "bt-me-01": ("mcq4","Before executing the upa escape, you must first:",["Create frames and push them off","Trap their arm and leg on the same side","Sit up and grab their collar","Turn toward them"],"Trap their arm and leg on the same side","Trapping gives you the fulcrum to complete the bridge-and-roll.",["mount","escapes"],2,None),
    "bt-me-02": ("trueFalse","Shrimping creates the space needed to execute the elbow-knee escape from mount.",["True","False"],"True","Shrimping hips creates the gap to insert your knee.",["mount","escapes"],1,None),
    "bt-bc-01": ("mcq4","When you have back control, where should your hooks be?",["Behind their knees","On their ankles","Inside their thighs","Outside their hips"],"Inside their thighs","Inside hooks limit hip mobility.",["back control"],1,None),
    "bt-bc-02": ("trueFalse","A body triangle is a stronger control than two hooks from the back.",["True","False"],"True","The body triangle locks the hips completely.",["back control"],2,None),
    "bt-sub-01": ("mcq4","When is it appropriate to tap in training?",["Only when you are about to be knocked out","Only if you have no way to escape","Whenever a submission is applied and you feel it working","Never — tapping is giving up"],"Whenever a submission is applied and you feel it working","Tapping early protects you from injury.",["submissions"],1,None),
    "bt-sub-02": ("trueFalse","A triangle choke works by compressing the carotid arteries, not the airway.",["True","False"],"True","Blood chokes cut off blood to the brain.",["submissions"],1,None),
    "bt-td-01": ("mcq4","After a successful takedown, your immediate priority is:",["Go for a submission immediately","Stand back up","Establish top position control","Call for a time-out"],"Establish top position control","Secure position first.",["takedowns"],2,None),
    "bt-td-02": ("trueFalse","In wrestling, a sprawl is used to defend against a double-leg shot.",["True","False"],"True","Sprawling drives your hips back and down to stuff the shot.",["takedowns"],1,None),
}

# Source question IDs per topic group
cg  = ["q-cg-01","q-cg-02","q-cg-03","q-cg-04","q-cg-05","q-cg-06","q-cg-07","q-cg-08"]
cga = ["q-cga-01","q-cga-02","q-cga-03","q-cga-04","q-cga-05","q-cga-06","q-cga-07","q-cga-08"]
gp  = ["q-gp-01","q-gp-02","q-gp-03","q-gp-04","q-gp-05","q-gp-06","q-gp-07","q-gp-08"]
sc  = ["q-sc-01","q-sc-02","q-sc-03","q-sc-04","q-sc-05","q-sc-06","q-sc-07","q-sc-08"]
sce = ["q-sce-01","q-sce-02","q-sce-03","q-sce-04","q-sce-05","q-sce-06","q-sce-07","q-sce-08"]
mc  = ["q-mc-01","q-mc-02","q-mc-03","q-mc-04","q-mc-05","q-mc-06","q-mc-07","q-mc-08"]
me  = ["q-me-01","q-me-02","q-me-03","q-me-04","q-me-05","q-me-06","q-me-07","q-me-08"]
bc  = ["q-bc-01","q-bc-02","q-bc-03","q-bc-04","q-bc-05","q-bc-06","q-bc-07","q-bc-08"]
sub = ["q-sub-01","q-sub-02","q-sub-03","q-sub-04","q-sub-05","q-sub-06","q-sub-07","q-sub-08"]
td  = ["q-td-01","q-td-02","q-td-03","q-td-04","q-td-05","q-td-06","q-td-07","q-td-08"]

UNIT_QUESTIONS = {
    "wb-01-l1": cg[0:4],
    "wb-01-l2": cg[4:8],
    "wb-02-l1": cga[0:4],
    "wb-02-l2": cga[4:8],
    "wb-03-l1": gp[0:4],
    "wb-03-l2": gp[4:8],
    "wb-mr-gg": [cg[0],cg[4],cga[0],cga[4],gp[0],gp[4]],
    "wb-me-gg": [cg[1],cg[5],cga[1],cga[5],gp[1],gp[5],cg[2],cga[2]],
    "wb-04-l1": sc[0:4],
    "wb-04-l2": sc[4:8],
    "wb-05-l1": sce[0:4],
    "wb-05-l2": sce[4:8],
    "wb-06-l1": mc[0:4],
    "wb-06-l2": mc[4:8],
    "wb-07-l1": me[0:4],
    "wb-07-l2": me[4:8],
    "wb-mr-tg": [sc[0],sc[4],sce[0],sce[4],mc[0],mc[4],me[0],me[4]],
    "wb-me-tg": [sc[1],sc[5],sce[1],sce[5],mc[1],mc[5],me[1],me[5]],
    "wb-08-l1": bc[0:4],
    "wb-08-l2": bc[4:8],
    "wb-09-l1": sub[0:4],
    "wb-09-l2": sub[4:8],
    "wb-10-l1": td[0:4],
    "wb-10-l2": td[4:8],
    "wb-mr-bs": [bc[0],bc[4],sub[0],sub[4],td[0],td[4]],
    "wb-me-bs": [bc[1],bc[5],sub[1],sub[5],td[1],td[5],bc[2],sub[2]],
    "wb-bt1": ["bt-cg-01","bt-cg-02","bt-cga-01","bt-cga-02","bt-gp-01","bt-gp-02",
               "bt-sc-01","bt-sc-02","bt-sce-01","bt-sce-02","bt-mc-01","bt-mc-02",
               "bt-me-01","bt-me-02","bt-bc-01","bt-bc-02","bt-sub-01","bt-sub-02",
               "bt-td-01","bt-td-02"],
}

REVIEW_EXAM_UNITS = {
    "wb-mr-gg","wb-me-gg","wb-mr-tg","wb-me-tg","wb-mr-bs","wb-me-bs","wb-bt1"
}


def build_question_dicts() -> list:
    rows = []
    seen = set()
    for unit_id, q_ids in UNIT_QUESTIONS.items():
        for i, src_qid in enumerate(q_ids):
            d = QUESTION_DATA[src_qid]
            fmt, prompt, opts, correct, expl, tags, diff, note = d
            new_id = f"{unit_id}-{i+1:02d}" if unit_id in REVIEW_EXAM_UNITS else src_qid
            if new_id in seen:
                continue
            seen.add(new_id)
            rows.append({
                "id": new_id,
                "unit_id": unit_id,
                "format": fmt,
                "prompt": prompt,
                "options": opts,
                "correct_answer": correct,
                "explanation": expl,
                "tags": tags,
                "difficulty": diff,
                "coach_note": note,
            })
    return rows


def main():
    print("Step 1: Clear old data...")
    rest_delete("unit_progress", "user_id=not.is.null")
    rest_delete("questions", "id=not.is.null")
    rest_delete("units", "id=not.is.null")
    print("  Done.")

    print("Step 2: Insert 31 units...")
    unit_dicts = build_unit_dicts()
    rest_insert("units", unit_dicts)
    count = rest_count("units")
    print(f"  Inserted. Total units: {count}")

    print("Step 3: Insert questions...")
    q_dicts = build_question_dicts()
    batch_size = 50
    for i in range(0, len(q_dicts), batch_size):
        batch = q_dicts[i:i+batch_size]
        rest_insert("questions", batch)
        print(f"  Batch {i//batch_size + 1}: {len(batch)} questions")

    total_q = rest_count("questions")
    print(f"  Done. Total questions: {total_q}")

    print("\nMigration complete!")
    print(f"  Units: {count}")
    print(f"  Questions: {total_q}")


if __name__ == "__main__":
    main()
