# Goodbye messages module

# Goodbye phrases; yeah I know they're cheesy, but I'm a dog person.
declare -a goodbye_text=(
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

# Get current date components for targeted holiday messaging
current_month=$(date +%m)
current_day=$(date +%d)
current_year=$(date +%Y)

# Check if we're in Christmas week (December 20-31)
is_christmas_week=$([[ "$current_month" == "12" && "$current_day" -ge 20 ]] && echo "true" || echo "false")

# Check if we're in New Year's period (December 30 - January 2)
is_new_years_period=$([[ "$current_month" == "12" && "$current_day" -ge 30 ]] && echo "true" || [[ "$current_month" == "01" && "$current_day" -le 2 ]] && echo "true" || echo "false")

# Check if we're in general holiday season (November-December)
is_holiday_season=$([[ "$current_month" == "11" || "$current_month" == "12" ]] && echo "true" || echo "false")

if [[ "$is_holiday_season" == "true" ]]; then
    # === GENERAL HOLIDAY SEASON (November-December) ===

    # Hanukkah (Festival of Lights) - can occur in Nov-Dec
    goodbye_text+=(
        "Happy Hanu-pup-kah!"
        "May your menorah be lit and your dreidel spin!"
        "Wishing you eight nights of latkes and fun!"
        "Hanukkah Sameach, my furry friend!"
    )

    # Kwanzaa (December 26 - January 1) - can start in Dec
    goodbye_text+=(
        "Habari Gani! (What's the news?) Happy Kwanzaa!"
        "May your Kwanzaa be filled with unity and joy!"
        "Celebrating the seven principles with my pack!"
        "Harambee! (Let's all work together!) Happy Kwanzaa!"
    )

    # General Festive Season
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

if [[ "$is_christmas_week" == "true" ]]; then
    # === CHRISTMAS WEEK (December 20-31) ===
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

if [[ "$is_new_years_period" == "true" ]]; then
    # === NEW YEAR'S PERIOD (December 30 - January 2) ===
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
