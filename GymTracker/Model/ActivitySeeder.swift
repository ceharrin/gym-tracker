import CoreData
import Foundation

struct ActivitySeeder {
    struct Preset {
        let name: String
        let category: ActivityCategory
        let icon: String
        let metric: PrimaryMetric
        let muscles: String?
        let instructions: String?
    }

    static let presets: [Preset] = [
        // MARK: - Strength
        Preset(
            name: "Squat",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Glutes, Hamstrings",
            instructions: "Stand with feet shoulder-width apart, toes slightly turned out.\nRest the bar on your upper traps and unrack it from the rack.\nBrace your core, take a deep breath, and hold it.\nDescend by pushing your knees out in line with your toes and sitting your hips back.\nLower until your thighs are parallel to the floor or below.\nDrive through your heels to stand back up.\nKeep your chest tall and back flat throughout the movement."
        ),
        Preset(
            name: "Deadlift",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Hamstrings, Glutes, Lower Back",
            instructions: "Stand with the bar over your mid-foot, feet hip-width apart.\nHinge at the hips and grip the bar just outside your legs.\nFlatten your back, lift your chest, and engage your lats.\nTake a deep breath and brace your core tightly.\nPush the floor away to initiate the lift, keeping the bar close to your shins.\nStand tall and squeeze your glutes at the top.\nHinge back down under control to return the bar to the floor."
        ),
        Preset(
            name: "Bench Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Chest, Triceps, Front Delts",
            instructions: "Lie flat on the bench with feet firmly planted on the floor.\nGrip the bar slightly wider than shoulder-width.\nRetract your shoulder blades and press them firmly into the bench.\nUnrack the bar and lower it to your mid-chest under control.\nPress the bar back up explosively to full arm extension.\nKeep your shoulder blades retracted and your arch consistent throughout."
        ),
        Preset(
            name: "Overhead Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Shoulders, Triceps",
            instructions: "Stand with feet shoulder-width apart, core braced.\nGrip the bar just outside your shoulders at collarbone height.\nPress the bar straight up, moving your head back slightly as it passes.\nLock out overhead with arms fully extended and elbows stacked over wrists.\nLower the bar under control back to the starting position.\nAvoid leaning back excessively — keep your glutes and core tight."
        ),
        Preset(
            name: "Barbell Row",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Back, Biceps",
            instructions: "Hinge forward to about 45 degrees with a flat back.\nGrip the bar slightly wider than shoulder-width, palms facing down.\nPull the bar toward your lower chest, driving your elbows back.\nSqueeze your shoulder blades together at the top of the pull.\nLower the bar under control to full arm extension.\nKeep your core braced and back flat throughout."
        ),
        Preset(
            name: "Pull-Up",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Lats, Biceps",
            instructions: "Hang from the bar with arms fully extended, grip slightly wider than shoulders.\nPull your shoulder blades down and back before initiating the movement.\nPull your chest toward the bar by driving your elbows down and back.\nLower yourself under control to the starting position.\nAvoid kipping or swinging to build real strength."
        ),
        Preset(
            name: "Chin-Up",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Lats, Biceps",
            instructions: "Hang from the bar with arms fully extended and palms facing toward you.\nPull your shoulder blades down before starting.\nPull your chin over the bar by driving your elbows back.\nLower slowly under control to full arm extension.\nKeep your core braced to avoid excessive swinging."
        ),
        Preset(
            name: "Leg Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Glutes",
            instructions: "Adjust the seat so your knees reach approximately 90 degrees at the bottom.\nPlace your feet hip-width apart on the platform.\nRelease the safety handles and lower the platform slowly.\nPress through your full foot to extend your legs.\nStop just short of locking your knees out at the top.\nReturn the safety handles when finished."
        ),
        Preset(
            name: "Leg Curl",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Hamstrings",
            instructions: "Lie face down on the machine with the pad resting just above your ankles.\nKeep your hips pressed into the pad throughout the movement.\nCurl your heels toward your glutes as far as comfortable.\nSqueeze your hamstrings at the top of the movement.\nLower the pad slowly back to the starting position.\nAvoid lifting your hips to use momentum."
        ),
        Preset(
            name: "Leg Extension",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads",
            instructions: "Sit in the machine with the pad resting just above your feet.\nKeep your back against the pad and knees at the edge of the seat.\nExtend your legs until straight, squeezing your quads at the top.\nHold briefly, then lower slowly under control.\nAvoid snapping your knees to full extension forcefully."
        ),
        Preset(
            name: "Chest Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Chest, Triceps",
            instructions: "Adjust the seat so the handles align with your mid-chest.\nGrip the handles and keep your back firmly against the pad.\nPress the handles forward until your arms are nearly extended.\nReturn slowly under control, stopping before the weight stack touches.\nKeep your shoulders relaxed and down throughout."
        ),
        Preset(
            name: "Lat Pulldown",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Lats, Biceps",
            instructions: "Adjust the knee pad to secure your thighs.\nGrip the bar wider than shoulder-width with palms facing away.\nSit tall and lean back very slightly.\nPull the bar to your upper chest by driving your elbows down and back.\nSqueeze your lats at the bottom of the movement.\nReturn the bar slowly to the starting position with control."
        ),
        Preset(
            name: "Seated Row",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Back, Biceps",
            instructions: "Sit with a slight forward lean and a flat back.\nGrip the handles with arms fully extended.\nPull the handles toward your lower abdomen, driving your elbows back.\nSqueeze your shoulder blades together at the end of the pull.\nReturn slowly under control with a slight forward lean.\nKeep your core braced and avoid rounding your back."
        ),
        Preset(
            name: "Shoulder Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Shoulders, Triceps",
            instructions: "Adjust the seat so the handles are level with your shoulders.\nGrip the handles and keep your back firmly against the pad.\nPress overhead until your arms are nearly fully extended.\nLower slowly under control back to shoulder height.\nKeep your core engaged to avoid arching your lower back."
        ),
        Preset(
            name: "Bicep Curl",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Biceps",
            instructions: "Stand with feet shoulder-width apart, dumbbells at your sides, palms forward.\nPin your elbows to your sides and keep them there throughout.\nCurl the weight up toward your shoulders by bending at the elbow.\nSqueeze your biceps at the top of the movement.\nLower slowly under control to the starting position.\nAvoid swinging your torso to generate momentum."
        ),
        Preset(
            name: "Triceps Pushdown",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Triceps",
            instructions: "Set the cable with a rope or bar at chest height.\nGrip the attachment and pin your elbows firmly to your sides.\nExtend your arms fully downward, spreading the rope ends apart at the bottom.\nSqueeze your triceps at the bottom of the movement.\nReturn slowly under control to the starting position.\nKeep your torso upright and avoid using body momentum."
        ),
        Preset(
            name: "Dumbbell Curl",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Biceps",
            instructions: "Hold dumbbells at your sides with palms facing forward or neutral.\nKeep your elbows stationary at your sides throughout.\nCurl the weights up, rotating your palms upward if starting neutral.\nSqueeze your biceps firmly at the top.\nLower slowly under control to the starting position.\nAlternate arms or perform both simultaneously."
        ),
        Preset(
            name: "Lateral Raise",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Lateral Delts",
            instructions: "Stand with dumbbells at your sides, palms facing inward.\nRaise your arms out to the sides, leading with your elbows.\nLift until your arms reach shoulder height — no higher.\nPause briefly at the top, feeling the lateral deltoids contract.\nLower slowly under control.\nAvoid shrugging your shoulders or using momentum."
        ),
        Preset(
            name: "Face Pull",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Rear Delts, Rotator Cuff",
            instructions: "Set the cable at face height and attach a rope.\nGrip the rope with both hands, thumbs pointing back.\nPull toward your face with your elbows high and flared out.\nExternally rotate your shoulders at the end, pulling the rope apart.\nRetract your shoulder blades at the peak of the movement.\nReturn slowly under control and repeat."
        ),
        Preset(
            name: "Romanian Deadlift",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Hamstrings, Glutes",
            instructions: "Stand holding the bar or dumbbells at hip level, feet hip-width apart.\nPush your hips back while hinging forward, keeping your back flat.\nLower the weight along the front of your legs until you feel a deep hamstring stretch.\nDrive your hips forward to return to standing.\nKeep a slight bend in your knees throughout.\nAvoid rounding your lower back — this is the most important cue."
        ),
        Preset(
            name: "Hip Thrust",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Glutes, Hamstrings",
            instructions: "Rest your upper back on the edge of a bench with feet hip-width apart.\nPlace the barbell across your hip crease, using a pad for comfort.\nDrive your hips upward by squeezing your glutes.\nLock out at the top until your body forms a straight line from shoulders to knees.\nKeep your chin tucked to maintain a neutral spine.\nLower slowly under control and repeat."
        ),
        Preset(
            name: "Plank",
            category: .strength, icon: "figure.core.training", metric: .duration,
            muscles: "Core",
            instructions: "Place your forearms on the floor with elbows directly under your shoulders.\nRise onto your toes so your body forms a straight line from head to heels.\nBrace your core as if bracing for a punch.\nSqueeze your glutes and thighs to add stability.\nBreathe steadily — do not hold your breath.\nHold for your target duration, keeping your hips level throughout."
        ),
        Preset(
            name: "Push-Up",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Chest, Triceps",
            instructions: "Place your hands slightly wider than shoulder-width on the floor.\nCreate a straight line from head to heels by bracing your core.\nLower your chest toward the floor under control.\nPress back up to full arm extension.\nKeep your elbows at roughly 45 degrees to your torso — not flared wide.\nModify by dropping to your knees if needed to maintain good form."
        ),
        Preset(
            name: "Dip",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Chest, Triceps",
            instructions: "Grip the parallel bars with arms fully extended.\nLean slightly forward for chest emphasis, or stay more upright for triceps.\nLower your body by bending your elbows until they reach about 90 degrees.\nPress back up to full arm extension.\nAvoid letting your shoulders roll forward at the bottom.\nUse an assisted machine or resistance band if you cannot perform full bodyweight dips."
        ),
        Preset(
            name: "Cable Fly",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Chest",
            instructions: "Set both cables at chest height and stand in the center.\nGrip the handles with a slight bend in your elbows.\nBring your hands together in a wide arc in front of your chest.\nSqueeze your chest at the point where your hands meet.\nReturn slowly to the starting position under control.\nAvoid letting your arms travel too far behind your body — stop when you feel a stretch."
        ),
        Preset(
            name: "Incline Bench Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Upper Chest, Triceps",
            instructions: "Set the bench to a 30-45 degree incline.\nLie back and grip the bar slightly wider than shoulder-width.\nUnrack the bar and lower it to your upper chest under control.\nPress the bar back up to full arm extension.\nKeep your shoulder blades retracted and your back against the bench.\nFocus on feeling the upper chest working rather than the front shoulder."
        ),

        // MARK: - Cardio
        Preset(
            name: "Running",
            category: .cardio, icon: "figure.run", metric: .distanceTime,
            muscles: nil,
            instructions: "Warm up with 5 minutes of walking or light jogging.\nLand mid-foot, not on your heel, to reduce impact on your joints.\nKeep your arms bent at 90 degrees and swing them forward and back, not across your body.\nMaintain an upright posture with a slight forward lean from the ankles.\nBreathe rhythmically, matching your breath pattern to your stride.\nCool down with 5 minutes of walking and light stretching."
        ),
        Preset(
            name: "Walking",
            category: .cardio, icon: "figure.walk", metric: .distanceTime,
            muscles: nil,
            instructions: "Stand tall with relaxed shoulders and your eyes forward.\nSwing your arms naturally in opposition to your legs.\nStrike your heel first and roll forward through to your toes.\nKeep a brisk, comfortable pace that slightly elevates your breathing.\nBreathe naturally and stay hydrated on longer walks.\nCool down by slowing your pace gradually for the final few minutes."
        ),
        Preset(
            name: "Treadmill",
            category: .cardio, icon: "figure.run", metric: .distanceTime,
            muscles: nil,
            instructions: "Hold the handrails when stepping onto the moving belt.\nStart at a slow pace to warm up before increasing speed.\nGradually increase speed or incline to your target intensity.\nAvoid leaning on the handrails during your workout — use them only for brief balance checks.\nMaintain good running form: mid-foot strike and upright posture.\nCool down with 3-5 minutes at a walking pace before stepping off."
        ),
        Preset(
            name: "Elliptical",
            category: .cardio, icon: "figure.elliptical", metric: .distanceTime,
            muscles: nil,
            instructions: "Step onto the moving pedals carefully and grip the handles.\nPush and pull the handles to engage your upper body and increase calorie burn.\nMaintain an upright posture — avoid hunching over the console.\nKeep your feet flat on the pedals throughout; avoid rising onto your toes.\nAdjust resistance and incline to reach your target intensity.\nCool down by reducing resistance in the final few minutes."
        ),
        Preset(
            name: "Rowing Machine",
            category: .cardio, icon: "oar.2.crossed", metric: .distanceTime,
            muscles: "Back, Arms, Core",
            instructions: "Sit on the seat and strap your feet securely into the footrests.\nGrip the handle with both hands, arms fully extended and back upright.\nThe stroke order is legs, then back, then arms — in that sequence.\nPush through your feet first, then lean back slightly, then pull the handle to your lower chest.\nReverse the sequence to return: extend arms, lean forward, then bend your knees to slide back.\nMaintain a smooth, controlled rhythm and aim for a consistent stroke rate."
        ),
        Preset(
            name: "Jump Rope",
            category: .cardio, icon: "figure.jumprope", metric: .duration,
            muscles: nil,
            instructions: "Hold the handles lightly with relaxed wrists.\nJump just high enough for the rope to clear your feet — no higher.\nKeep your elbows close to your sides and turn the rope from your wrists.\nLand softly on the balls of your feet with knees slightly bent.\nStart with a slow, comfortable pace to find your rhythm, then build speed.\nRest as needed and increase your duration progressively over sessions."
        ),
        Preset(
            name: "Stair Climber",
            category: .cardio, icon: "figure.stair.stepper", metric: .duration,
            muscles: "Quads, Glutes",
            instructions: "Step on carefully and hold the rails only while getting started.\nSet a moderate, sustainable pace and stand tall throughout.\nPush through your full foot on each pedal — not just your toes.\nAvoid leaning your bodyweight heavily onto the rails, which reduces the workout benefit.\nKeep your core engaged and breathe steadily.\nCool down with a slower pace for the final 2-3 minutes."
        ),

        // MARK: - Swimming
        Preset(
            name: "Freestyle",
            category: .swimming, icon: "figure.pool.swim", metric: .lapsTime,
            muscles: "Full Body",
            instructions: "Push off the wall in a streamlined position with arms extended overhead.\nRotate your hips and shoulders side to side with each arm stroke.\nReach as far forward as possible with each arm entry.\nExhale steadily underwater and inhale quickly when rotating your head to breathe.\nKick steadily from your hips with relaxed, pointed feet.\nFocus on smooth, efficient technique over maximum speed."
        ),
        Preset(
            name: "Backstroke",
            category: .swimming, icon: "figure.pool.swim", metric: .lapsTime,
            muscles: "Back, Shoulders",
            instructions: "Float on your back with your body as horizontal and near the surface as possible.\nAlternate your arms in a windmill motion, entering the water pinky-first.\nPull each arm down along your body from shoulder to hip.\nKick steadily with a flutter kick originating from your hips.\nBreathe naturally — your face remains above water throughout.\nKeep your head still and look straight up at the ceiling."
        ),
        Preset(
            name: "Breaststroke",
            category: .swimming, icon: "figure.pool.swim", metric: .lapsTime,
            muscles: "Chest, Legs",
            instructions: "Glide forward in a streamlined position with arms extended.\nPull your arms outward and back in a wide arc while rising to breathe.\nBring your heels toward your glutes, then kick outward and together in a frog motion.\nThe timing flows: pull, breathe, kick, glide — each phase into the next.\nGlide fully between strokes to maximise efficiency.\nKeep your hips near the surface to minimise drag."
        ),
        Preset(
            name: "Butterfly",
            category: .swimming, icon: "figure.pool.swim", metric: .lapsTime,
            muscles: "Shoulders, Back",
            instructions: "Push off in a streamlined position with arms overhead.\nUndulate your hips and perform two dolphin kicks per arm stroke cycle.\nBring both arms over the water simultaneously and enter pinky-side first.\nPull both arms together in a keyhole pattern under your body.\nBreath by lifting your head forward on the pull phase, keeping it low.\nBuild duration gradually — butterfly is demanding, so prioritise form over speed."
        ),
        Preset(
            name: "Mixed Strokes",
            category: .swimming, icon: "figure.pool.swim", metric: .lapsTime,
            muscles: "Full Body",
            instructions: "Choose 2-4 strokes to rotate through across your laps.\nRest at the wall briefly between strokes to maintain good form.\nAdjust your breathing technique for each stroke.\nThis format develops balanced strength and reduces monotony.\nTrack your laps per stroke to monitor improvements over time.\nFocus on technique in each stroke rather than maximum speed."
        ),
        Preset(
            name: "Open Water Swim",
            category: .swimming, icon: "figure.open.water.swim", metric: .distanceTime,
            muscles: "Full Body",
            instructions: "Sight every 6-10 strokes by briefly lifting your head to look forward.\nSwim with a partner or within sight of safety support at all times.\nWear a brightly coloured swim cap to stay visible to watercraft.\nCheck conditions before entering — currents, temperature, and weather.\nStart with shorter distances until you are comfortable navigating open water.\nAlways tell someone where you are going and when you expect to finish."
        ),

        // MARK: - Cycling
        Preset(
            name: "Road Cycling",
            category: .cycling, icon: "bicycle", metric: .distanceTime,
            muscles: "Quads, Glutes, Calves",
            instructions: "Always wear a properly fitted helmet before riding.\nAdjust your saddle so your knee has a slight bend at the bottom of the pedal stroke.\nMaintain a smooth cadence of around 80-100 rpm by shifting gears proactively.\nScan the road well ahead and signal turns clearly with your hand.\nRide predictably, follow road rules, and stay visible.\nCarry water and a snack for rides over 60 minutes."
        ),
        Preset(
            name: "Stationary Bike",
            category: .cycling, icon: "bicycle", metric: .distanceTime,
            muscles: "Quads, Glutes",
            instructions: "Adjust the seat height so your knee has a slight bend at the bottom of the pedal stroke.\nSet handlebar height for a comfortable, upright or slightly forward lean.\nChoose a resistance level that challenges you while maintaining your target cadence.\nPedal smoothly through the full rotation rather than just pushing down.\nStay hydrated with regular sips throughout your session.\nCool down with 3-5 minutes of easy, low-resistance pedalling."
        ),
        Preset(
            name: "Mountain Biking",
            category: .cycling, icon: "bicycle", metric: .distanceTime,
            muscles: "Full Body",
            instructions: "Always wear a helmet and appropriate protective gear including gloves.\nLower your saddle slightly on technical terrain for better control and stability.\nShift your weight backward on descents and forward on climbs.\nLook ahead to where you want to go, not directly at obstacles.\nBrake before corners — not during them — to maintain control.\nStart with easier trails and progress to more technical terrain gradually."
        ),
        Preset(
            name: "Spin Class",
            category: .cycling, icon: "bicycle", metric: .duration,
            muscles: "Quads, Glutes",
            instructions: "Arrive a few minutes early to adjust the bike before class starts.\nAdjust seat height, handlebar height, and seat fore/aft position for comfort.\nFollow the instructor's cues for resistance changes and position shifts.\nStand up on climbs when instructed, keeping your core engaged and weight centred.\nPace your effort to last the full session — avoid going all-out at the start.\nCool down and stretch after class to aid recovery."
        ),

        // MARK: - Yoga & Flexibility
        Preset(
            name: "Yoga",
            category: .yoga, icon: "figure.yoga", metric: .duration,
            muscles: "Full Body",
            instructions: "Move slowly and mindfully between poses, never rushing transitions.\nInhale to prepare for a movement and exhale to deepen into it.\nNever force a stretch — work to your edge where you feel sensation, not pain.\nKeep joints soft rather than locked, especially knees and elbows.\nModify poses using blocks, straps, or blankets if needed.\nFocus on your breath throughout — it guides the practice and calms the mind."
        ),
        Preset(
            name: "Pilates",
            category: .yoga, icon: "figure.pilates", metric: .duration,
            muscles: "Core, Full Body",
            instructions: "Gently engage your core before every movement begins.\nMove slowly and with precise control, not momentum.\nKeep the natural curves of your spine unless a specific curl or imprint is called for.\nBreathe rhythmically — exhale on the effort phase of each movement.\nFocus on quality over quantity; fewer controlled repetitions beat many sloppy ones.\nStop and modify any exercise that causes joint pain."
        ),
        Preset(
            name: "Stretching",
            category: .yoga, icon: "figure.flexibility", metric: .duration,
            muscles: "Full Body",
            instructions: "Warm up muscles lightly before stretching — never stretch cold muscles deeply.\nHold each stretch for 20-30 seconds and breathe slowly throughout.\nNever bounce in a stretch — hold it steadily.\nWork to the point of mild tension, not pain.\nStretch both sides equally and pay extra attention to your tightest areas.\nIncorporate stretching after workouts when muscles are warm for best results."
        ),
        Preset(
            name: "Foam Rolling",
            category: .yoga, icon: "figure.flexibility", metric: .duration,
            muscles: "Full Body",
            instructions: "Place the foam roller under the target muscle group.\nApply moderate bodyweight pressure — enough to feel it without sharp pain.\nRoll slowly along the muscle at about 1 inch per second.\nWhen you find a tender spot, pause there for 20-30 seconds and breathe.\nAvoid rolling directly over joints, bones, or your lower spine.\nSpend 30-60 seconds on each area and keep breathing steadily throughout."
        ),

        // MARK: - HIIT
        Preset(
            name: "HIIT",
            category: .hiit, icon: "bolt.heart.fill", metric: .duration,
            muscles: "Full Body",
            instructions: "Warm up for 5 minutes with light cardio and dynamic stretching.\nAlternate between high-intensity bursts of 20-40 seconds and rest or low-intensity periods of 10-20 seconds.\nPush to 80-95% of your maximum effort during the work intervals.\nChoose compound movements such as sprints, burpees, or jump squats for maximum effect.\nCool down for at least 5 minutes after the session.\nLimit HIIT to 2-3 sessions per week to allow full recovery."
        ),
        Preset(
            name: "Tabata",
            category: .hiit, icon: "bolt.heart.fill", metric: .duration,
            muscles: "Full Body",
            instructions: "Choose one or two compound exercises for the session.\nWork at maximum intensity for exactly 20 seconds.\nRest for exactly 10 seconds.\nRepeat for 8 rounds to complete one full Tabata — 4 minutes total.\nRecord your reps each round to track progress over time.\nRest 1-2 minutes before starting another Tabata round with a different exercise."
        ),
        Preset(
            name: "Circuit Training",
            category: .hiit, icon: "arrow.triangle.2.circlepath", metric: .duration,
            muscles: "Full Body",
            instructions: "Select 5-8 exercises covering upper body, lower body, and core movements.\nPerform each exercise for a set time or rep count with minimal rest between them.\nRest for 1-2 minutes after completing all exercises in the circuit.\nAim for 2-4 complete circuits per session depending on your fitness level.\nScale movements and load to match your current ability.\nProgress by shortening rest periods or adding a circuit each week."
        ),
        Preset(
            name: "CrossFit",
            category: .hiit, icon: "bolt.heart.fill", metric: .duration,
            muscles: "Full Body",
            instructions: "Review the WOD (Workout of the Day) carefully before starting.\nScale the movements and weights to match your current ability — there is no shame in scaling.\nPrioritise correct form over speed or heavier loads, especially on Olympic lifts.\nWork at a challenging but sustainable pace rather than burning out in the first round.\nLog your results: time, rounds completed, and weights used.\nRest and recover fully between high-intensity sessions."
        ),
        Preset(
            name: "Burpees",
            category: .hiit, icon: "bolt.heart.fill", metric: .weightReps,
            muscles: "Full Body",
            instructions: "Start standing with feet shoulder-width apart.\nBend your knees and place your hands on the floor in front of you.\nJump or step your feet back to a plank position.\nPerform a push-up, then jump or step your feet forward to your hands.\nExplosively jump up with arms reaching overhead.\nLand softly with knees slightly bent to absorb the impact.\nMaintain a brisk but controlled pace and breathe rhythmically throughout."
        ),
    ]

    static func seedIfNeeded(context: NSManagedObjectContext) {
        let req = CDActivity.fetchRequest()
        req.predicate = NSPredicate(format: "isPreset == true")
        guard (try? context.count(for: req)) == 0 else {
            updateInstructionsIfNeeded(context: context)
            return
        }

        for preset in presets {
            let activity = CDActivity(context: context)
            activity.id = UUID()
            activity.name = preset.name
            activity.category = preset.category.rawValue
            activity.icon = preset.icon
            activity.primaryMetric = preset.metric.rawValue
            activity.muscleGroups = preset.muscles
            activity.instructions = preset.instructions
            activity.isPreset = true
            activity.createdAt = Date()
        }

        try? context.save()
    }

    static func updateInstructionsIfNeeded(context: NSManagedObjectContext) {
        let req = CDActivity.fetchRequest()
        req.predicate = NSPredicate(format: "isPreset == true AND instructions == nil")
        guard let activities = try? context.fetch(req), !activities.isEmpty else { return }

        let instructionsByName: [String: String] = Dictionary(
            uniqueKeysWithValues: presets.compactMap { p in
                p.instructions.map { (p.name, $0) }
            }
        )

        for activity in activities {
            activity.instructions = instructionsByName[activity.name]
        }

        try? context.save()
    }
}
