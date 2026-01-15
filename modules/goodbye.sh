# Goodbye messages module
# I get that this file is unnecessary, so I left it optional for program functionality.
# Standalone builds will not include this file.

# Check if running on low-spec machine (less than 2 CPU cores or less than 2GB RAM)
# If so, limit to 15 phrases for better performance
is_low_spec=false
cpu_cores=$(nproc 2>/dev/null || echo "1")
total_ram_kb=$(grep -E '^MemTotal:' /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "2097152") # Default to 2GB if can't read

# More accurate GB calculation: divide by 1048576 (1024*1024) and round up
total_ram_gb=$(( (total_ram_kb + 524287) / 1048576 )) # Add half of divisor for rounding

if [[ $cpu_cores -lt 2 || $total_ram_gb -lt 2 ]]; then
    is_low_spec=true
fi

# Debug: ensure variables are set
: "${is_low_spec:=false}"
: "${cpu_cores:=1}"
: "${total_ram_gb:=2}"

# Goodbye phrases; yeah I know they're cheesy, but I'm a dog person.
declare -a goodbye_text=(
    # Basic fallback messages in case conditional logic fails
    "Woof woof! (Goodbye!)"
    "Tail wags for now!"
    "Stay paw-sitive!"
    "Bark at you later!"
    "Paws for thought!"
)

if [[ "$is_low_spec" == "true" ]]; then
    # === LOW-SPEC MACHINE: LIMITED TO 15 PHRASES ===
    # Classic favorites for better performance
    goodbye_text=(
        "Woof woof! (Goodbye!)"
        "Tail wags for now!"
        "Stay paw-sitive!"
        "Bark at you later!"
        "Paws for thought!"
        "Stay furry, my friend!"
        "You're the leader of the pack!"
        "Wag more, bark less!"
        "Everything is paw-sible!"
        "You're a real treat!"
        "Stay paw-some!"
        "Happy trails and wagging tails!"
        "A wagging tail is a happy heart!"
        "You're a fur-midable human!"
        "That's all, folks! Woof!"
    )
else
    # === FULL PHRASE SET FOR NORMAL MACHINES ===
    goodbye_text=(
        # === CLASSIC DOG PUNS ===
        "Woof woof! (Goodbye!)"
        "Tail wags for now!"
        "Catch you at the park!"
        "See you later, pup!"
        "Bone-voyage!"
        "Stay paw-sitive!"
        "Paws out!"
        "Fur-well!"
        "Un-leash the fun until next time!"
        "Stop, drop, and roll over!"
        "Hope your day is paw-some!"
        "Bark at you later!"
        "Have a howling good time!"
        "Don't work too hard, stay ruff!"
        "Keep your tail held high!"
        "Stay furry, my friend!"
        "A round of a-paws for your work today!"
        "Fur-ever yours!"
        "Sniff you soon!"
        "Be the good boy I know you are!"
        "Time to go for a walkies!"
        "Back to the kennel!"
        "Rest your paws!"
        "Stay fetching!"
        "Don't stop re-triever-ing!"
        "Paws and reflect on a job well done!"
        "You're the leader of the pack!"
        "Wag more, bark less!"
        "Life is ruff, but you're doing great!"
        "Everything is paw-sible!"
        "You're a real treat!"
        "No more digging for today!"
        "Go fetch some rest!"
        "Stay paws-ed until we meet again!"
        "A-woooooo! (See ya!)"
        "Keep on wagging!"
        "Hope your dreams are full of squirrels!"
        "Keep your nose to the ground!"
        "Stay loyal to the yard!"
        "You've earned a gold medal in fetching!"
        "Quit hounding me and go play!"
        "See you in the dog days!"
        "You're the top dog!"
        "Don't let the cat get your tongue!"
        "Pawsitively finished for now!"
        "Time to curl up and nap!"
        "Lick you later!"
        "Sniff out some fun!"
        "Keep your ears up!"
        "Stay paw-some!"
        "Woofing you all the best!"
        "Catch you on the flip-flop (or the flip-paw)!"
        "Happy trails and wagging tails!"
        "Don't bark up the wrong tree!"
        "You're a fur-midable human!"
        "Stay dogged in your pursuits!"
        "A wagging tail is a happy heart!"
        "Chew on that until next time!"
        "Paws for thought!"

        # === CLASSIC DOG PUNS (ADDITIONAL) ===
        "Paws and relax!"
        "Stay out of the doghouse!"
        "Time to fetch some Z's!"
        "Keep your fur dry!"
        "Bark less, wag more!"
        "Stay off the naughty list!"
        "Don't go chasing mailmen!"
        "Keep your bowl full!"
        "May your ball always return!"
        "Stay away from the vet!"

        # === PLAYFUL & ENERGETIC ===
        "Zoomies time! Bye!"
        "Gotta chase my tail now!"
        "Off to dig up some fun!"
        "Time for squirrel patrol!"
        "Gotta mark my territory elsewhere!"
        "Fetch ya later, alligator!"
        "In a while, crocodog!"
        "Going on a sniffari!"
        "Time to herd some cats!"
        "Off to the dog park!"

        # === SWEET & AFFECTIONATE ===
        "You're the best human ever!"
        "Thanks for the scritches!"
        "You're my favorite walker!"
        "Stay as sweet as peanut butter!"
        "You're the treat at the end of my day!"
        "Keep being wonderful!"
        "You deserve all the belly rubs!"
        "Stay as cozy as my favorite blanket!"
        "You're purebred awesome!"
        "Stay as loyal as a golden!"

        # === SLEEPY/NAP THEMED ===
        "Time for my 18-hour nap!"
        "Off to dream of bacon!"
        "Gotta catch up on my beauty sleep!"
        "My bed is calling!"
        "Time to curl up in my sunspot!"
        "Off to my crate for a snooze!"
        "My pillow awaits!"
        "Time to power-nap!"
        "Gotta recharge my woofers!"
        "Even guard dogs need rest!"

        # === FOOD/TREAT THEMED ===
        "Hope your day is full of treats!"
        "Stay as yummy as a pup cup!"
        "May your kibble bowl never empty!"
        "Don't forget the cheese tax!"
        "Stay tasty!"
        "Off to investigate the treat jar!"
        "Hope you find a surprise snack!"
        "Stay well-fed and happy!"
        "May your biscuits be plentiful!"
        "Dinner time calls!"

        # === ADVENTURE THEMED ===
        "Off to explore new smells!"
        "Gotta check my pee-mail!"
        "Time to patrol the perimeter!"
        "Adventure awaits!"
        "Off to follow an interesting scent!"
        "New fire hydrants await!"
        "Gotta survey the backyard!"
        "Time to guard the house!"
        "Off on a secret mission!"
        "The great outdoors calls!"

        # === WISE DOG WISDOM ===
        "Remember: every human is pet-able!"
        "The mailman is just doing his job!"
        "Sometimes you just need to howl at the moon!"
        "Every stick is a potential treasure!"
        "Don't be afraid to get muddy!"
        "Chase your dreams like they're squirrels!"
        "Sometimes sitting is the best activity!"
        "Trust your nose!"
        "The best things in life are sniffed, not seen!"
        "Always leave room for dessert (and treats)!"

        # === SILLY & ABSURD ===
        "I must go, my people need me!"
        "The squirrels are plotting, must investigate!"
        "My butt needs sniffing elsewhere!"
        "Gotta go stare at a wall!"
        "The vacuum cleaner is suspiciously quiet..."
        "I think I heard a plastic bag!"
        "Was that the cheese drawer?!"
        "Must bark at nothing important!"
        "The doorbell on TV might ring!"
        "Someone might be at the door (probably not)!"

        # === ENCOURAGING & MOTIVATIONAL ===
        "You've got this! Woof!"
        "Stay strong like a mastiff!"
        "Be brave like a chihuahua!"
        "Stay clever like a border collie!"
        "Be friendly like a labrador!"
        "Stay determined like a terrier!"
        "Be majestic like a husky!"
        "Stay graceful like a greyhound!"
        "Be noble like a german shepherd!"
        "Stay charming like a corgi!"

        # === TECH/NERD DOG ===
        "Turning off my bark-ery system!"
        "Shutting down my wag processor!"
        "Rebooting my sniffer!"
        "Logging out of the yard!"
        "Saving my progress!"
        "Game over, time for walkies!"
        "Achievement unlocked: Good Human!"
        "Level complete! See you next time!"
        "Quitting to main menu (the couch)!"
        "Save point reached!"

        # === PHILOSOPHICAL DOG ===
        "To fetch or not to fetch, that is the question!"
        "I think, therefore I wag!"
        "The unexamined bone is not worth burying!"
        "We are what we repeatedly sniff!"
        "The only thing I know is that I know nothing (except where the treats are)!"
        "Carpe Canem - seize the dog!"
        "Wagito ergo sum - I wag, therefore I am!"
        "The bark of existence!"
        "Sniffing the meaning of life!"
        "Ponder the eternal stick!"

        # === MOVIE/TV REFERENCES ===
        "I'll be bark!"
        "May the force be with woof!"
        "Live long and pawsper!"
        "To infinity and bone-yond!"
        "You're a wizard, Harry (the dog)!"
        "I'll get you, my pretty, and your little cat too!"
        "Here's looking at you, pup!"
        "You can't handle the truth (about squirrels)!"
        "I feel the need... the need for speed (chasing balls)!"
        "Keep your friends close, but your treats closer!"

        # === MUSICAL DOG ===
        "Another one bites the bone!"
        "Don't stop be-lieving (in treats)!"
        "All you need is love (and belly rubs)!"
        "I will always love chew!"
        "Sweet Caroline (good bones never seemed so good)!"
        "Like a rolling bone!"
        "Who let the dogs out? (It was me!)"
        "Walking on sunshine (and sniffing everything)!"
        "Don't worry, be happy (like a dog)!"
        "And I will always love you (human)!"

        # === SPORTS DOG ===
        "Touchdown! Game over!"
        "Goal! Time for treats!"
        "Home run! See you at home plate!"
        "Slam dunk! Nap time!"
        "Checkmate! The cat loses again!"
        "Winner winner chicken dinner!"
        "Gold medal in napping achieved!"
        "World record in tail wagging!"
        "Champion of the couch!"
        "MVP - Most Valuable Pooch!"

        # === INTERNATIONAL FLAIR ===
        "Arrivederci, amico cane!"
        "Au revoir, mon chien!"
        "Auf Wiedersehen, Hund!"
        "Sayonara, inu-san!"
        "Adiós, perrito!"
        "Do svidaniya, sobaka!"
        "Zài jiàn, gǒu!"
        "Tot ziens, hondje!"
        "Hej då, hund!"
        "Farvel, hund!"

        # === FINAL SWEET ONES ===
        "You make my tail wag!"
        "Thanks for being my human!"
        "I'll dream of you and treats!"
        "You're my favorite part of the day!"
        "Can't wait to see you again!"
        "I'll save the best sniff for you!"
        "You're the treat I never have to earn!"
        "My heart is full (and so is my belly)!"
        "You're simply puptastic!"
        "Stay wonderful, you amazing human!"

        # === ONE LAST CLASSIC ===
        "That's all, folks! Woof!"
    )
fi

# Get current date components for targeted holiday messaging
current_month=$(date +%m)
current_day=$(date +%d)
current_year=$(date +%Y)

# Check various holiday periods
is_christmas_week=$([[ "$current_month" == "12" && "$current_day" -ge 20 ]] && echo "true" || echo "false")
is_new_years_period=$([[ "$current_month" == "12" && "$current_day" -ge 30 ]] && echo "true" || [[ "$current_month" == "01" && "$current_day" -le 2 ]] && echo "true" || echo "false")
is_holiday_season=$([[ "$current_month" == "11" || "$current_month" == "12" ]] && echo "true" || echo "false")
is_valentines_day=$([[ "$current_month" == "02" && "$current_day" == "14" ]] && echo "true" || echo "false")
is_easter_season=$([[ "$current_month" == "03" || "$current_month" == "04" ]] && echo "true" || echo "false")
is_halloween=$([[ "$current_month" == "10" && "$current_day" == "31" ]] && echo "true" || echo "false")
is_summer=$([[ "$current_month" == "06" || "$current_month" == "07" || "$current_month" == "08" ]] && echo "true" || echo "false")
is_fall=$([[ "$current_month" == "09" || "$current_month" == "10" ]] && echo "true" || echo "false")
is_spring=$([[ "$current_month" == "03" || "$current_month" == "04" || "$current_month" == "05" ]] && echo "true" || echo "false")

# Add holiday messages based on current date
if [[ "$is_holiday_season" == "true" ]]; then
    # === GENERAL HOLIDAY SEASON (November-December) ===

    # Hanukkah (Festival of Lights) - can occur in Nov-Dec
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Happy Hanu-pup-kah!")
    else
        goodbye_text+=(
            "Happy Hanu-pup-kah!"
            "May your menorah be lit and your dreidel spin!"
            "Wishing you eight nights of latkes and fun!"
            "Hanukkah Sameach, my furry friend!"
        )
    fi

    # Kwanzaa (December 26 - January 1) - can start in Dec
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Habari Gani! Happy Kwanzaa!")
    else
        goodbye_text+=(
            "Habari Gani! (What's the news?) Happy Kwanzaa!"
            "May your Kwanzaa be filled with unity and joy!"
            "Celebrating the seven principles with my pack!"
            "Harambee! (Let's all work together!) Happy Kwanzaa!"
        )
    fi

    # General Festive Season
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Season's Greetings from your favorite pup!")
    else
        goodbye_text+=(
            "Season's Greetings from your favorite pup!"
            "May your season be filled with joy and treats!"
            "Happy Holidays! Stay warm and well-fed!"
            "Festive wishes from your loyal canine companion!"
            "May your winter be cozy and your holidays bright!"
            "Happy Solstice! Enjoy the lengthening days!"
            "Winter blessings and warm snuggles to you!"
        )
    fi
fi

if [[ "$is_christmas_week" == "true" ]]; then
    # === CHRISTMAS WEEK (December 20-31) ===
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Merry Lick-mas!")
    else
        goodbye_text+=(
            "Merry Lick-mas!"
            "Happy Howl-idays!"
            "Merry Paws-mas!"
            "Have a very woofy Christmas!"
            "Jingle all the way... to the treat jar!"
            "Santa Paws is coming to town!"
            "Hope your holidays are filled with chew toys!"
            "Wishing you a tail-waggingly merry Christmas!"
            "May your Christmas be merry and your bones bright!"
            "Deck the halls with lots of dog treats!"
            "Have a holly jolly Christmas, pup!"
            "Santa's favorite helper says goodbye!"
        )
    fi
fi

if [[ "$is_new_years_period" == "true" ]]; then
    # === NEW YEAR'S PERIOD (December 30 - January 2) ===
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Happy New Year! May it be filled with belly rubs!")
    else
        goodbye_text+=(
            "Happy New Year! May it be filled with belly rubs!"
            "Here's to a pawsome new year ahead!"
            "New Year's resolution: More treats and walks!"
            "May your new year be merry and your resolutions achievable!"
            "Happy New Year! Wishing you 365 days of adventure!"
            "New Year, new walks, new treats - same great pup!"
            "May your New Year be filled with endless belly rubs!"
            "Here's to a year of more fetch and fewer baths!"
            "Happy New Year! May all your dreams come true (and include treats)!"
            "New Year's wish: May your bowl never be empty!"
        )
    fi
fi

if [[ "$is_valentines_day" == "true" ]]; then
    # === VALENTINE'S DAY (February 14) ===
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Happy Valentine's Day! You're the pick of my litter!")
    else
        goodbye_text+=(
            "Happy Valentine's Day! You're the pick of my litter!"
            "Will you be my Valen-pup-tine?"
            "You're the love of my doggy life!"
            "Roses are red, violets are blue, you're my favorite human, woof woof to you!"
            "Happy Valentine's Day! May your day be filled with love and treats!"
            "You're my valentine - the best human ever!"
            "Love you more than bacon! Happy Valentine's Day!"
            "Be my Valentine? I'll share my treats with you!"
            "Happy Valentine's Day! You're paws-itively amazing!"
            "Sending tail wags and lots of love your way!"
        )
    fi
fi

if [[ "$is_easter_season" == "true" ]]; then
    # === EASTER/SPRING SEASON (March-May) ===
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Happy Easter! May your basket be full of treats!")
    else
        goodbye_text+=(
            "Happy Easter! May your basket be full of treats!"
            "Happy Spring! Time for walks and bunny hops!"
            "Easter greetings from your favorite Easter pup!"
            "May your Easter be egg-stra special!"
            "Spring has sprung! Time for outdoor adventures!"
            "Happy Easter! Hoppy holidays to you!"
            "Springtime wishes and tail wags!"
            "May your spring be filled with flowers and fun!"
            "Easter blessings and bunny kisses!"
            "Spring forward into more playtime!"
        )
    fi
fi

if [[ "$is_halloween" == "true" ]]; then
    # === HALLOWEEN (October 31) ===
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Happy Halloween! Don't let the cat get your candy!")
    else
        goodbye_text+=(
            "Happy Halloween! Don't let the cat get your candy!"
            "Boo! Happy Halloween from your spooky pup!"
            "Trick or treat? I'd rather have belly rubs!"
            "Happy Halloween! May your night be full of treats and no tricks!"
            "Ghosts and goblins, beware! This pup protects his humans!"
            "Happy Howl-oween! Have a spooktacular night!"
            "Costume check: I'm a dog, what's your excuse?"
            "Happy Halloween! Stay safe and have fun!"
            "Bark at the moon, howl with delight! Happy Halloween!"
            "May your Halloween be filled with candy and costumes!"
        )
    fi
fi

# === SEASONAL MESSAGES (General seasons, not specific holidays) ===
if [[ "$is_summer" == "true" ]]; then
    # Summer season
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Stay cool this summer! Enjoy the sunny days!")
    else
        goodbye_text+=(
            "Stay cool this summer! Enjoy the sunny days!"
            "Summer vibes and beach walks!"
            "May your summer be filled with sunshine and fun!"
            "Hot dog days are here! Stay hydrated!"
            "Summer adventures await!"
        )
    fi
elif [[ "$is_fall" == "true" ]]; then
    # Fall season
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Enjoy the crisp fall air and colorful leaves!")
    else
        goodbye_text+=(
            "Enjoy the crisp fall air and colorful leaves!"
            "Fall scents are the best - pumpkin and leaves!"
            "Cozy sweaters and autumn walks!"
            "May your fall be filled with harvest treats!"
            "Pumpkin spice and everything nice!"
        )
    fi
elif [[ "$is_spring" == "true" ]]; then
    # Spring season (overlaps with Easter but more general)
    if [[ "$is_low_spec" == "true" ]]; then
        goodbye_text+=("Spring has sprung! Time for fresh air and walks!")
    else
        goodbye_text+=(
            "Spring has sprung! Time for fresh air and walks!"
            "Flower power! Enjoy the blooming season!"
            "Spring cleaning time - fresh walks for everyone!"
            "May your spring be filled with new beginnings!"
            "Birds singing, flowers blooming, walks calling!"
        )
    fi
fi

# Debug: check array size
# echo "Debug: goodbye_text array has ${#goodbye_text[@]} elements" >&2

# Ensure we always have at least some goodbye messages
if [[ ${#goodbye_text[@]} -eq 0 ]]; then
    goodbye_text=(
        "Woof woof! (Goodbye!)"
        "Tail wags for now!"
        "Stay paw-sitive!"
        "Bark at you later!"
        "Paws for thought!"
    )
fi
