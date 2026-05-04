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
            name: "Back Squat",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Glutes, Hamstrings",
            instructions: "Rest the bar on your upper back and brace your core before unracking.\nSit down between your hips while keeping your chest tall and knees tracking over your toes.\nDrive through your whole foot to stand back up under control."
        ),
        Preset(
            name: "Front Squat",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Core, Upper Back",
            instructions: "Rack the bar across the front of your shoulders with elbows high.\nStay upright as you descend, keeping your core braced and knees forward.\nDrive up smoothly while keeping your elbows lifted."
        ),
        Preset(
            name: "Box Squat",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Glutes, Hamstrings",
            instructions: "Set a box behind you at an appropriate height and squat back to it with control.\nPause briefly while staying braced, then drive up through your feet.\nAvoid collapsing onto the box or rocking for momentum."
        ),
        Preset(
            name: "Deadlift",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Hamstrings, Glutes, Lower Back",
            instructions: "Set the bar over your mid-foot, brace hard, and pull the slack out before lifting.\nPush the floor away while keeping the bar close to your legs.\nStand tall at the top, then hinge back down under control."
        ),
        Preset(
            name: "Romanian Deadlift",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Hamstrings, Glutes",
            instructions: "Start tall with the weight at your hips and hinge back with soft knees.\nLower until you feel a strong hamstring stretch while keeping your back flat.\nDrive your hips forward to return to standing."
        ),
        Preset(
            name: "Sumo Deadlift",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Glutes, Hamstrings, Adductors",
            instructions: "Set your feet wider than shoulder-width with toes turned out and hands inside your knees.\nBrace, push your knees out, and drive the floor apart as you lift.\nFinish tall without overleaning back."
        ),
        Preset(
            name: "Good Morning",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Hamstrings, Glutes, Lower Back",
            instructions: "Place the bar on your upper back and unlock your knees slightly.\nHinge forward by sending your hips back while keeping your spine neutral.\nReturn to standing by squeezing your glutes."
        ),
        Preset(
            name: "Hip Thrust",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Glutes, Hamstrings",
            instructions: "Set your upper back on a bench with the bar across your hips.\nDrive your hips up until your torso is parallel to the floor and squeeze your glutes.\nLower under control without losing tension."
        ),
        Preset(
            name: "Barbell Lunge",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Glutes, Hamstrings",
            instructions: "Carry the bar on your upper back and step into a long, stable stride.\nLower until both knees are bent, then push through the front foot to return.\nStay tall and controlled on every rep."
        ),
        Preset(
            name: "Barbell Split Squat",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Glutes",
            instructions: "Set up in a split stance with the bar balanced on your upper back.\nLower straight down while keeping your front foot planted and torso braced.\nDrive through the front leg to stand back up."
        ),
        Preset(
            name: "Bench Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Chest, Triceps, Front Delts",
            instructions: "Set your shoulder blades and feet before unracking the bar.\nLower to your mid-chest with control, then press back up explosively.\nKeep your upper back tight for the whole set."
        ),
        Preset(
            name: "Incline Bench Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Upper Chest, Triceps",
            instructions: "Use a moderate incline and keep your shoulder blades retracted on the bench.\nLower the bar to your upper chest and press back to lockout.\nAvoid shrugging your shoulders forward."
        ),
        Preset(
            name: "Close-Grip Bench Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Triceps, Chest",
            instructions: "Grip the bar just inside shoulder-width and keep your elbows tucked.\nLower to the lower chest with control and press up while staying tight through the upper back.\nUse a range of motion you can control cleanly."
        ),
        Preset(
            name: "Overhead Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Shoulders, Triceps",
            instructions: "Start with the bar at shoulder height and your core braced.\nPress in a straight line overhead while moving your head slightly back, then through.\nLower smoothly without overextending your lower back."
        ),
        Preset(
            name: "Push Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Shoulders, Triceps, Legs",
            instructions: "Dip a few inches with a vertical torso, then drive powerfully through your legs.\nTransfer that momentum into a strong overhead press.\nFinish with locked-out arms and control the descent."
        ),
        Preset(
            name: "Barbell Row",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Back, Biceps",
            instructions: "Hinge into a strong torso position and keep your trunk still.\nPull the bar toward your lower ribs by driving your elbows back.\nLower to full extension without losing posture."
        ),
        Preset(
            name: "Pendlay Row",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Back, Lats, Biceps",
            instructions: "Start each rep from the floor with your torso nearly parallel to the ground.\nRow explosively into your lower chest or upper abdomen.\nSet the bar back down every rep to reset your position."
        ),
        Preset(
            name: "Shrug",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Traps",
            instructions: "Stand tall with the bar in your hands and arms straight.\nRaise your shoulders straight up toward your ears without rolling them.\nPause briefly, then lower under control."
        ),
        Preset(
            name: "Pull-Up",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Lats, Biceps",
            instructions: "Start from a dead hang and set your shoulders down before pulling.\nDrive your elbows down to bring your chest toward the bar.\nLower all the way back to a controlled hang."
        ),
        Preset(
            name: "Chin-Up",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Lats, Biceps",
            instructions: "Use an underhand grip and pull from a full hang with your core braced.\nLead with your chest and elbows until your chin clears the bar.\nLower under control without swinging."
        ),
        Preset(
            name: "Push-Up",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .reps,
            muscles: "Chest, Triceps, Shoulders",
            instructions: "Create a straight line from shoulders to heels and brace your core.\nLower your chest toward the floor with elbows at about 45 degrees.\nPress back up without letting your hips sag."
        ),
        Preset(
            name: "Dip",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .reps,
            muscles: "Chest, Triceps",
            instructions: "Support yourself on the bars with shoulders packed down.\nLower until your elbows are around ninety degrees, then press back up.\nStay controlled and avoid collapsing at the bottom."
        ),
        Preset(
            name: "Goblet Squat",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Quads, Glutes, Core",
            instructions: "Hold the dumbbell tight to your chest and keep your elbows close.\nSit down between your hips while staying tall.\nDrive through your whole foot to return to standing."
        ),
        Preset(
            name: "Dumbbell Bench Press",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Chest, Triceps, Front Delts",
            instructions: "Set your shoulder blades on the bench and hold the dumbbells over your chest.\nLower with control until your upper arms reach a comfortable depth.\nPress back up while keeping both sides even."
        ),
        Preset(
            name: "Incline Dumbbell Press",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Upper Chest, Triceps",
            instructions: "Use a moderate incline and keep your shoulder blades set.\nLower the dumbbells with control and press them back up over your shoulders.\nKeep your wrists stacked and elbows controlled."
        ),
        Preset(
            name: "Dumbbell Floor Press",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Chest, Triceps",
            instructions: "Lie on the floor with knees bent and dumbbells over your chest.\nLower until your upper arms touch the floor lightly.\nPress back up while keeping your shoulders stable."
        ),
        Preset(
            name: "Dumbbell Fly",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Chest",
            instructions: "Press the dumbbells up, then open your arms in a wide arc with a soft elbow bend.\nLower only as far as you can control while keeping tension on the chest.\nBring the dumbbells back together over your chest."
        ),
        Preset(
            name: "Dumbbell Shoulder Press",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Shoulders, Triceps",
            instructions: "Start with the dumbbells at shoulder height and your core braced.\nPress overhead without flaring your ribs.\nLower back to shoulder level under control."
        ),
        Preset(
            name: "Arnold Press",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Shoulders, Triceps",
            instructions: "Start with palms facing you at shoulder height.\nRotate your hands outward as you press overhead.\nReverse the path smoothly on the way down."
        ),
        Preset(
            name: "Lateral Raise",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Lateral Delts",
            instructions: "Lift the dumbbells out to your sides with a soft elbow bend.\nStop around shoulder height and avoid shrugging up.\nLower slowly to keep tension on the delts."
        ),
        Preset(
            name: "Front Raise",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Front Delts",
            instructions: "Raise the dumbbells forward to shoulder height while keeping your torso still.\nPause briefly without swinging.\nLower under control."
        ),
        Preset(
            name: "Rear Delt Fly",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Rear Delts, Upper Back",
            instructions: "Hinge forward with a flat back and let the dumbbells hang below you.\nOpen your arms wide, leading with your elbows.\nSqueeze the rear delts, then lower with control."
        ),
        Preset(
            name: "One-Arm Dumbbell Row",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Back, Lats, Biceps",
            instructions: "Brace one hand on a bench and keep your spine neutral.\nRow the dumbbell toward your hip by driving your elbow back.\nLower fully before the next rep."
        ),
        Preset(
            name: "Chest-Supported Dumbbell Row",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Upper Back, Lats",
            instructions: "Lie chest-down on an incline bench with dumbbells hanging below you.\nPull your elbows up and back without lifting your chest off the bench.\nLower slowly to a full stretch."
        ),
        Preset(
            name: "Dumbbell Shrug",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Traps",
            instructions: "Stand tall with the dumbbells at your sides.\nLift your shoulders straight up and pause.\nLower slowly without rolling them."
        ),
        Preset(
            name: "Dumbbell Romanian Deadlift",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Hamstrings, Glutes",
            instructions: "Hold the dumbbells at your sides and hinge back with soft knees.\nLower along your legs while keeping your spine neutral.\nDrive your hips through to stand tall."
        ),
        Preset(
            name: "Dumbbell Walking Lunge",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Quads, Glutes, Hamstrings",
            instructions: "Carry the dumbbells at your sides and take a controlled step forward.\nLower into a lunge, then bring the back leg through into the next step.\nStay balanced and upright through the set."
        ),
        Preset(
            name: "Dumbbell Split Squat",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Quads, Glutes",
            instructions: "Hold the dumbbells at your sides in a split stance.\nLower straight down while keeping pressure through the front foot.\nDrive back up without wobbling."
        ),
        Preset(
            name: "Step-Up",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Quads, Glutes",
            instructions: "Place one foot fully on the box or bench.\nDrive through that leg to stand up without pushing off the floor too much.\nStep down under control and repeat."
        ),
        Preset(
            name: "Dumbbell Curl",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Biceps",
            instructions: "Keep your elbows pinned at your sides as you curl the weights.\nSqueeze at the top and lower slowly.\nAvoid swinging your torso."
        ),
        Preset(
            name: "Hammer Curl",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Biceps, Brachialis, Forearms",
            instructions: "Hold the dumbbells with a neutral grip and keep your elbows still.\nCurl straight up without rotating your hands.\nLower under control."
        ),
        Preset(
            name: "Overhead Triceps Extension",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Triceps",
            instructions: "Hold a dumbbell overhead with elbows pointing up.\nLower behind your head while keeping your upper arms mostly still.\nExtend back to full lockout."
        ),
        Preset(
            name: "Leg Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Glutes",
            instructions: "Set your feet firmly on the platform and lower with control until your knees are comfortably bent.\nPress through your full foot to extend the sled.\nDo not slam into lockout at the top."
        ),
        Preset(
            name: "Hack Squat",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Glutes",
            instructions: "Set your shoulders under the pads and place your feet in a stable stance.\nLower until you reach a strong squat depth you can control.\nDrive back up through your feet while staying braced."
        ),
        Preset(
            name: "Smith Machine Squat",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads, Glutes",
            instructions: "Position your feet so the fixed bar path still allows a balanced squat.\nDescend with control and keep your torso braced.\nStand back up without bouncing off the bottom."
        ),
        Preset(
            name: "Smith Machine Bench Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Chest, Triceps",
            instructions: "Set the bench so the fixed path aligns with your pressing groove.\nLower with control to your chest and press back to full extension.\nKeep your shoulders pinned to the bench."
        ),
        Preset(
            name: "Smith Machine Incline Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Upper Chest, Triceps",
            instructions: "Use a modest incline and align the bench to the Smith path.\nLower to your upper chest, then press back up smoothly.\nStay tight through your upper back."
        ),
        Preset(
            name: "Leg Curl",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Hamstrings",
            instructions: "Set the pad just above your heels and keep your hips stable.\nCurl smoothly through a full range without jerking.\nLower under control to keep tension on the hamstrings."
        ),
        Preset(
            name: "Leg Extension",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Quads",
            instructions: "Sit tall with the machine aligned to your knee joint.\nExtend your legs until your quads contract hard, then lower with control.\nAvoid snapping into lockout."
        ),
        Preset(
            name: "Chest Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Chest, Triceps",
            instructions: "Adjust the seat so the handles line up with your chest.\nPress smoothly until your arms are nearly straight, then return under control.\nKeep your shoulders down and back."
        ),
        Preset(
            name: "Incline Chest Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Upper Chest, Triceps",
            instructions: "Set the seat so the handles start near your upper chest.\nPress evenly through both arms and lower slowly.\nStay pinned to the pad throughout."
        ),
        Preset(
            name: "Pec Deck",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Chest",
            instructions: "Set the seat so your elbows stay level with the machine arms.\nBring your forearms or hands together in front of your chest.\nOpen back up slowly without overstretching."
        ),
        Preset(
            name: "Rear Delt Machine",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Rear Delts, Upper Back",
            instructions: "Sit tall against the pad and grip the rear-delt handles.\nOpen your arms by driving the elbows back and out.\nReturn slowly to the start."
        ),
        Preset(
            name: "Lat Pulldown",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Lats, Biceps",
            instructions: "Secure your thighs and start from a long overhead reach.\nPull the bar toward your upper chest by driving your elbows down.\nControl the return all the way up."
        ),
        Preset(
            name: "Seated Cable Row",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Back, Biceps",
            instructions: "Sit tall with a neutral spine and reach forward to a full stretch.\nRow the handle toward your lower ribs by driving your elbows back.\nReturn slowly without rounding your back."
        ),
        Preset(
            name: "High Row Machine",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Upper Back, Lats",
            instructions: "Start with a full reach and chest supported if available.\nDrive your elbows down and back in the machine’s path.\nLower slowly to keep tension in the upper back."
        ),
        Preset(
            name: "Assisted Pull-Up",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .reps,
            muscles: "Lats, Biceps",
            instructions: "Set the assistance so you can move through a full range of motion.\nPull with your back and arms until your chin clears the bar.\nLower all the way back to the bottom under control."
        ),
        Preset(
            name: "Shoulder Press",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Shoulders, Triceps",
            instructions: "Set the handles to shoulder level and keep your back against the pad.\nPress overhead smoothly and lower with control.\nAvoid arching your lower back to finish reps."
        ),
        Preset(
            name: "Bicep Curl",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Biceps",
            instructions: "Set the machine or cable so your elbows stay planted in the same position.\nCurl through a full range and squeeze the biceps at the top.\nLower slowly without letting the weight yank you down."
        ),
        Preset(
            name: "Triceps Pushdown",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Triceps",
            instructions: "Pin your elbows to your sides and press the attachment down to full extension.\nPause briefly, then return under control.\nKeep your torso steady and avoid swinging."
        ),
        Preset(
            name: "Cable Chest Fly",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Chest",
            instructions: "Set the pulleys around chest height and take a staggered stance.\nBring the handles together in a wide arc while keeping a soft elbow bend.\nReturn slowly until you feel a controlled stretch."
        ),
        Preset(
            name: "Cable Row",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Back, Lats, Biceps",
            instructions: "Set your torso tall and pull the cable handle toward your torso.\nDrive your elbow back and squeeze through the upper back.\nReturn to a full stretch under control."
        ),
        Preset(
            name: "Face Pull",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Rear Delts, Rotator Cuff",
            instructions: "Set the rope at face height and pull toward your forehead with elbows high.\nSeparate the rope as you finish to engage the rear delts and upper back.\nReturn slowly without losing posture."
        ),
        Preset(
            name: "Straight-Arm Pulldown",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Lats",
            instructions: "Stand tall with arms extended on a high cable attachment.\nPull down in an arc toward your thighs without bending your elbows much.\nReturn slowly to the overhead start."
        ),
        Preset(
            name: "Cable Lateral Raise",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Lateral Delts",
            instructions: "Use the low pulley and raise your arm out to the side with a soft elbow.\nLift to shoulder height without shrugging.\nLower slowly to keep continuous tension."
        ),
        Preset(
            name: "Cable Curl",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Biceps",
            instructions: "Set the cable low and keep your elbows by your sides.\nCurl smoothly to your shoulders and squeeze at the top.\nLower slowly without leaning back."
        ),
        Preset(
            name: "Rope Hammer Curl",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Biceps, Forearms",
            instructions: "Use a rope on the low cable and keep your palms facing each other.\nCurl with your elbows pinned in place and squeeze at the top.\nLower with control."
        ),
        Preset(
            name: "Overhead Cable Triceps Extension",
            category: .strength, icon: "dumbbell.fill", metric: .weightReps,
            muscles: "Triceps",
            instructions: "Face away from the cable and keep your elbows pointing forward.\nExtend your arms until straight, then bend them back with control.\nKeep the upper arms mostly fixed."
        ),
        Preset(
            name: "Cable Crunch",
            category: .strength, icon: "figure.core.training", metric: .reps,
            muscles: "Core",
            instructions: "Kneel facing the cable and hold the rope near your temples.\nCrunch your ribs toward your hips while keeping your hips mostly still.\nReturn under control to a long spine."
        ),
        Preset(
            name: "Pallof Press",
            category: .strength, icon: "figure.core.training", metric: .reps,
            muscles: "Core, Obliques",
            instructions: "Stand side-on to the cable and hold the handle at your chest.\nPress straight out without letting your torso rotate.\nPause, then bring the handle back in under control."
        ),
        Preset(
            name: "Glute Cable Kickback",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Glutes",
            instructions: "Attach the cable to your ankle and brace onto a stable support.\nDrive your leg back by squeezing the glute without arching your lower back.\nReturn slowly to the start."
        ),
        Preset(
            name: "Hip Abduction",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Glute Medius, Glutes",
            instructions: "Sit tall in the machine and press your knees outward against the pads.\nPause briefly at the end range.\nReturn slowly without letting the stack slam."
        ),
        Preset(
            name: "Hip Adduction",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Adductors",
            instructions: "Sit tall and bring your legs together against the pads.\nSqueeze at the midpoint, then return with control.\nKeep your torso steady."
        ),
        Preset(
            name: "Calf Raise Machine",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .weightReps,
            muscles: "Calves",
            instructions: "Press through the balls of your feet to rise onto your toes.\nPause at the top for a strong calf contraction.\nLower to a full stretch under control."
        ),
        Preset(
            name: "Bodyweight Squat",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .reps,
            muscles: "Quads, Glutes",
            instructions: "Stand with feet shoulder-width apart and brace your core.\nSit down between your hips while keeping your chest tall.\nStand back up through your whole foot."
        ),
        Preset(
            name: "Bulgarian Split Squat",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .reps,
            muscles: "Quads, Glutes",
            instructions: "Place your back foot on a bench and keep most of your weight on the front leg.\nLower with control until the front thigh is near parallel.\nDrive back up through the front foot."
        ),
        Preset(
            name: "Glute Bridge",
            category: .strength, icon: "figure.strengthtraining.traditional", metric: .reps,
            muscles: "Glutes, Hamstrings",
            instructions: "Lie on your back with knees bent and feet planted.\nDrive your hips up by squeezing your glutes.\nLower under control without resting fully between reps."
        ),
        Preset(
            name: "Plank",
            category: .strength, icon: "figure.core.training", metric: .duration,
            muscles: "Core",
            instructions: "Set your elbows under your shoulders and make a straight line from head to heels.\nBrace your abs and glutes hard.\nHold steady without letting your hips sag."
        ),
        Preset(
            name: "Hanging Leg Raise",
            category: .strength, icon: "figure.core.training", metric: .reps,
            muscles: "Core, Hip Flexors",
            instructions: "Hang from the bar and keep your torso as still as possible.\nRaise your legs by bracing your abs rather than swinging.\nLower slowly to the start."
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
        let existingPresets = (try? context.fetch(req)) ?? []
        let existingNames = Set(existingPresets.map(\.name))

        var insertedAny = false
        for preset in presets where !existingNames.contains(preset.name) {
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
            insertedAny = true
        }

        if insertedAny {
            try? context.save()
        }

        updateInstructionsIfNeeded(context: context)
    }

    /// Removes duplicate preset activities that CloudKit sync can introduce after a reinstall.
    /// When duplicates are found, all workout-entry references are migrated to the oldest
    /// copy (by createdAt) before the extras are deleted.
    static func deduplicatePresets(context: NSManagedObjectContext) {
        let req = CDActivity.fetchRequest()
        req.predicate = NSPredicate(format: "isPreset == true")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        guard let activities = try? context.fetch(req) else { return }

        var seen: [String: CDActivity] = [:]
        var duplicates: [CDActivity] = []

        for activity in activities {
            let key = activity.name
            if let survivor = seen[key] {
                if let entries = activity.entries as? Set<CDWorkoutEntry> {
                    for entry in entries {
                        entry.activity = survivor
                    }
                }
                duplicates.append(activity)
            } else {
                seen[key] = activity
            }
        }

        guard !duplicates.isEmpty else { return }
        duplicates.forEach { context.delete($0) }
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
