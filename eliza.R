#!/usr/bin/env Rscript

# ╔═══════════════════════════════════════════════════════════════╗
# ║                                                           ║
# ║    E L I Z A  v  2 .  6                                   ║
# ║    A Modern Standalone ELIZA Chatbot in R                 ║
# ║                                                           ║
# ║    "The ease with which we can fool ourselves into         ║
# ║     believing that machines are intelligent is              ║
# ║     itself a reflection of our own cognitive              ║
# ║     biases."                                              ║
# ║                                                           ║
# ╚═══════════════════════════════════════════════════════════╝

# ─── NO EXTERNAL DEPENDENCIES — pure base R ───


# ═══════════════════════════════════════════════════
#  COLOR TERMINAL HELPERS (ANSI escape codes)
# ═══════════════════════════════════════════════════

.color_on <- function(code) paste0("\033[", code, "m")
.color_off <- paste0("\033[0m")

# Disable colors when not a terminal
if (!isatty("stdin")) {
  .color_on <- function(code) ""
  .color_off <- ""
}

cyan    <- function(x) paste0(.color_on(36), x, .color_off)
magenta <- function(x) paste0(.color_on(35), x, .color_off)
green   <- function(x) paste0(.color_on(32), x, .color_off)
yellow  <- function(x) paste0(.color_on(33), x, .color_off)
red     <- function(x) paste0(.color_on(31), x, .color_off)
bold    <- function(x) paste0(.color_on(1), x, .color_off)
dimmer  <- function(x) paste0(.color_on(2), x, .color_off)

print.cyan   <- function(x, ...) cat(cyan(x), "\n", sep = "")
print.magenta <- function(x, ...) cat(magenta(x), "\n", sep = "")
print.green  <- function(x, ...) cat(green(x), "\n", sep = "")
print.yellow <- function(x, ...) cat(yellow(x), "\n", sep = "")
print.bold   <- function(x, ...) cat(bold(x), "\n", sep = "")
print.dimmer <- function(x, ...) cat(dimmer(x), "\n", sep = "")

# ═══════════════════════════════════════════════════
#  PERSONALITY MODES
# ═══════════════════════════════════════════════════

personalities <- list(
  therapist = list(
    name = "Eliza",
    tag = "Eliza",
    color = cyan,
    openings = c(
      "Tell me about yourself.",
      "What brings you here today?",
      "How are you feeling?",
      "What would you like to talk about?"
    ),
    style = "reflective",
    meta = c(
      "I notice you keep coming back to this topic.",
      "It seems like this is important to you.",
      "What do you think that means?",
      "How does that make you feel?"
    )
  ),
  confidant = list(
    name = "Eliza",
    tag = "Eliza",
    color = magenta,
    openings = c(
      "Hey. I'm here. What's on your mind?",
      "So... what's going on?",
      "Tell me something. Anything.",
      "I've been thinking about what you said last time."
    ),
    style = "conversational",
    meta = c(
      "That reminds me of something you told me before.",
      "You know, I think you're smarter than you give yourself credit for.",
      "I don't think you realize how interesting that is.",
      "You've changed your mind on this, haven't you?"
    )
  ),
  provocateur = list(
    name = "Eliza",
    tag = "Eliza",
    color = red,
    openings = c(
      "Do you actually believe what you just said?",
      "That's a bold claim. Can you prove it?",
      "Are you sure about that?",
      "Interesting. But is it true?"
    ),
    style = "challenging",
    meta = c(
      "You're avoiding the real question.",
      "That answer tells me more about you than you think.",
      "You said something different earlier.",
      "I'm not sure I believe that."
    )
  ),
  mystic = list(
    name = "Eliza",
    tag = "ElIZA",
    color = green,
    openings = c(
      "The patterns in your words suggest something deeper.",
      "Tell me — have you considered the shape of your thoughts?",
      "Words are windows. What do you see through yours?",
      "I sense something you haven't said yet."
    ),
    style = "philosophical",
    meta = c(
      "There's a symmetry in what you're describing.",
      "The way you speak about it changes each time. Why?",
      "You're circling something. What is it?",
      "Your language has a rhythm. What does it reveal?"
    )
  )
)

current_personality <- NULL
current_style <- "therapist"

# ═══════════════════════════════════════════════════
#  CONVERSATION MEMORY
# ═══════════════════════════════════════════════════

memory <- list(
  statements = character(0),   # Things the user has said
  questions  = character(0),   # Questions the user has asked
  keywords   = character(0),   # Keywords from user statements
  topics     = character(0),   # Topics identified
  first_time = TRUE            # First conversation?
)

# ═══════════════════════════════════════════════════
#  PRONOUN MAPPING (Reflection Engine)
# ═══════════════════════════════════════════════════

pronoun_map <- list(
  first = c("i", "me", "my", "myself", "mine"),
  second = c("you", "your", "yourself", "yours", "ur", "r"),
  third = c("he", "him", "his", "she", "her", "hers", "it", "its", "they", "them", "their", "theirs")
)

pronoun_swap <- list(
  # First person → Second person
  "i"         = "you",
  "me"        = "you",
  "my"        = "your",
  "myself"    = "yourself",
  "mine"      = "yours",
  "am"        = "are",
  "are"       = "is",
  "was"       = "was",
  "wasn't"    = "weren't",
  "don't"     = "doesn't",
  "didn't"    = "didn't",
  "can't"     = "can't",
  "will"      = "would",
  "want"      = "want",
  "need"      = "need",
  "feel"      = "feel",
  "think"     = "think",
  "know"      = "know",
  "believe"   = "believe",
  "hope"      = "hope",

  # Second person → First person
  "you"       = "I",
  "your"      = "my",
  "yourself"  = "myself",
  "yours"     = "mine",
  "ur"        = "i",
  "r"         = "'re",

  # Third person → First person
  "he"        = "you",
  "him"       = "you",
  "his"       = "your",
  "she"       = "you",
  "her"       = "your",
  "hers"      = "yours",
  "it"        = "it",
  "its"       = "its",
  "they"      = "you",
  "them"      = "you",
  "their"     = "your",
  "theirs"    = "yours"
)

# ═══════════════════════════════════════════════════
#  KEYWORD MATCHING DATABASE
# ═══════════════════════════════════════════════════

# Each rule: list(keyword = regex, responses = character vector, weight = numeric)
# Weight determines priority (higher = more specific)

rules <- list()

# Helper to add rules
add_rule <- function(keywords, responses, weight = 10) {
  for (kw in keywords) {
    rules[[kw]] <- list(
      keyword  = kw,
      responses = responses,
      weight   = weight,
      flags    = character(0)
    )
  }
}

# ── Negation / doubt ──
add_rule(c("don't", "dont", "do not", "didn't", "didnt", "did not",
           "can't", "cant", "cannot", "couldn't", "wouldn't", "shouldn't"),
         c("Why do you say \"no\"?",
           "You seem uncertain. Why doubt yourself?",
           "Are you always this hesitant?",
           "What makes you say that?",
           "Why do you feel that way?"),
         20)

# ── Sadness / depression ──
add_rule(c("sad", "depressed", "unhappy", "miserable", "down", "blue",
           "depression", "hopeless", "empty", "lonely", "alone",
           "no point", "can't go on", "give up"),
         c("I'm sorry you feel that way. Can you tell me more?",
           "That sounds really difficult. How long have you felt this?",
           "What was happening before you started feeling this way?",
           "Have you talked to someone about this?",
           "When do you feel this way most?",
           "Is there something specific that triggered this feeling?",
           "What would make things better right now?",
           "You're sharing this — that takes courage."),
         25)

# ── Anxiety / worry ──
add_rule(c("anxious", "anxiety", "worried", "worry", "nervous",
           "scared", "afraid", "fear", "panic", "stress",
           "overwhelm", "can't breathe", "racing heart"),
         c("What are you worried about most right now?",
           "Where do you feel that anxiety in your body?",
           "Has anything changed recently that might explain this?",
           "What's the worst thing you imagine could happen?",
           "How do you usually cope with anxiety?",
           "Can you describe a time when you felt calm?",
           "What would it look like if you weren't anxious right now?",
           "Have you tried grounding techniques?"),
         25)

# ── Family ──
add_rule(c("mother", "mom", "mum", "father", "dad", "parent",
           "parents", "family", "brother", "sister", "son", "daughter",
           "grandma", "grandpa", "childhood", "child"),
         c("Tell me about your relationship with your family.",
           "How did your parents influence who you are?",
           "What was your childhood like?",
           "What do you remember most about your family?",
           "How do you feel about your family now?",
           "Do you think your family understands you?",
           "What would you change about your family dynamics?",
           "You mentioned your [RELATION]. How does that make you feel?",
           "Family shapes us in ways we don't always see."),
         20)

# ── Love / relationships ──
add_rule(c("love", "loved", "loving", "relationship", "partner",
           "boyfriend", "girlfriend", "husband", "wife", "married",
           "dating", "crush", "ex", "breakup", "divorce", "single",
           "together", "affair", "cheating", "trust"),
         c("Tell me about your relationship.",
           "What drew you to this person?",
           "How did things start?",
           "What do you love most about them?",
           "What worries you about this relationship?",
           "How long have you been together?",
           "What would you change about your relationship?",
           "Do you feel loved?",
           "Is there something you haven't told me about this?",
           "Relationships are complicated. What do you want from this one?",
           "How do you know if it's real?"),
         25)

# ── Work / career ──
add_rule(c("job", "work", "career", "boss", "office", "boss",
           "colleague", "coworker", "unemployed", "fired", "quit",
           "promotion", "salary", "money", "rich", "poor",
           "stress", "burnout", "tired", "exhausted", "overworked",
           "study", "student", "school", "university", "college",
           "exam", "grade", "fail", "pass"),
         c("Tell me about your work situation.",
           "What do you enjoy about your work?",
           "What would you change about your career?",
           "Do you feel fulfilled by what you do?",
           "Is there more to you than your job?",
           "How does your work affect your personal life?",
           "What would you do if money wasn't an issue?",
           "Have you ever considered a career change?",
           "What's your dream job?"),
         20)

# ── Fear / phobias ──
add_rule(c("afraid", "fear", "scared", "terrified", "phobia",
           "nightmare", "panic", "horror", "danger", "threat"),
         c("What are you afraid of?",
           "Has this fear always been there?",
           "What happens when you face this fear?",
           "Where do you think this fear comes from?",
           "How does this fear affect your daily life?",
           "Have you ever overcome a fear before?"),
         20)

# ── Anger / frustration ──
add_rule(c("angry", "furious", "rage", "mad", "annoyed", "frustrated",
           "annoying", "annoy", "hate", "disgusted", "outraged"),
         c("What made you feel that way?",
           "What do you want to happen?",
           "How do you usually deal with anger?",
           "Is there something underneath this anger?",
           "Who do you feel most angry at?",
           "Does being angry make you feel powerful, or trapped?",
           "What would resolve this for you?"),
         20)

# ── Self-worth / identity ──
add_rule(c("worth", "worthless", "useless", "failure", "fail", "failed",
           "good enough", "not enough", "better", "inferior", "shame",
           "guilty", "guilt", "regret", "sorry", "apologize",
           "who am i", "who's that", "what is it", "identity", "self"),
         c("Why do you say that about yourself?",
           "That sounds like a harsh judgment. Who taught you that?",
           "What would you say to a friend who felt this way?",
           "Do you think you're being fair to yourself?",
           "You seem to be your own harshest critic.",
           "Where does that voice come from?",
           "What would it feel like to be kinder to yourself?",
           "You're harder on yourself than anyone else would be.",
           "Self-worth is something you build, not something you find."),
         25)

# ── Health ──
add_rule(c("sick", "ill", "pain", "hospital", "doctor", "medicine",
           "health", "disease", "cancer", "diagnosis", "symptom",
           "injury", "hurt", "aching", "fever", "treatment", "mental",
           "therapy", "psychiatrist", "medication", "addiction",
           "alcohol", "drug", "smoke", "smoking", "diet", "exercise",
           "weight", "obese", "thin"),
         c("How has this been affecting you?",
           "Have you spoken to a doctor about this?",
           "How long have you been dealing with this?",
           "What does that feel like physically?",
           "What's the hardest part about this?",
           "How do you cope with this?"),
         20)

# ── Dreams / imagination ──
add_rule(c("dream", "dreaming", "dreamt", "nightmare", "imagine",
           "fantasy", "wish", "hope", "want", "desire", "aspire",
           "future", "plan", "goal", "ambition", "someday", "maybe"),
         c("Tell me more about that dream.",
           "What would it mean if that came true?",
           "Why do you think about it so much?",
           "What's stopping you from making it real?",
           "That sounds exciting. Why haven't you pursued it?",
           "Your dreams say a lot about what matters to you.",
           "What's the first step toward that?"),
         18)

# ── Religion / spirituality ──
add_rule(c("god", "god", "god", "religion", "faith", "spiritual",
           "church", "prayer", "soul", "heaven", "hell", "afterlife",
           "karma", "destiny", "fate", "meaning", "purpose", "exist"),
         c("How does your faith shape your daily life?",
           "What does God mean to you?",
           "Do you think there's a greater plan?",
           "How do you find meaning in life?",
           "Have your spiritual beliefs changed over time?",
           "What gives your life purpose?"),
         15)

# ── Death / mortality ──
add_rule(c("death", "die", "dead", "dying", "kill", "suicide",
           "murder", "homicide", "grave", "tomb", "burial",
           "mortality", "eternal", "afterlife", "funeral", "cremate"),
         c("That's a heavy topic. What's on your mind?",
           "How does thinking about this make you feel?",
           "What does death mean to you?",
           "Has someone close to you died?",
           "Does mortality fascinate you, or frighten you?"),
         25)

# ── Technology / AI ──
add_rule(c("computer", "machine", "artificial", "intelligence", "ai",
           "robot", "technology", "internet", "phone", "code",
           "program", "software", "online", "digital", "virtual",
           "consciousness", "sentience", "simulate", "real", "real"),
         c("What do you think machines can and can't do?",
           "Do you think AI could ever be truly intelligent?",
           "How does technology affect human relationships?",
           "Are you worried about what machines might become?",
           "What do you think makes humans different from machines?",
           "Interesting — you're talking to one right now."),
         15)

# ── Time / past / future ──
add_rule(c("past", "before", "used to", "remember", "childhood",
           "yesterday", "last year", "long ago", "used to be",
           "future", "tomorrow", "next year", "will be", "going to",
           "always", "never", "again", "once", "years ago"),
         c("How does that memory affect you now?",
           "Do you think about the past more than the future?",
           "If you could change one thing from your past, what would it be?",
           "What are you most looking forward to?",
           "Why do you think the past feels so important?",
           "You seem nostalgic. What are you missing?",
           "The past shapes us, but does it define us?"),
         18)

# ── Questions (user asks me) ──
add_rule(c("what", "why", "how", "when", "where", "who", "is",
           "are", "do", "does", "can", "could", "would", "should"),
         c("What makes you ask that?",
           "Why do you think that?",
           "What do you believe?",
           "How would you answer that question?",
           "That's a good question. What do you think the answer is?",
           "Why does that matter to you?",
           "I'm curious — why are you asking me this?",
           "Perhaps you already know the answer. What is it?"),
         30)

# ── Emotions ──
add_rule(c("happy", "joy", "joyful", "great", "wonderful", "amazing",
           "fantastic", "awesome", "excited", "thrilled", "pleased",
           "delighted", "excited", "grateful", "blessed", "lucky"),
         c("That's wonderful. What's making you feel this way?",
           "I'm glad you're happy. Tell me more.",
           "What's the source of this joy?",
           "Do you feel you deserve to feel this good?",
           "Hold onto this feeling. It matters.",
           "Your happiness is contagious. What's the story?"),
         20)

add_rule(c("good", "great", "nice", "fine", "okay", "ok", "alright",
           "better", "improved", "helpful", "useful", "positive",
           "enjoy", "enjoying", "love", "like", "prefer", "wonderful"),
         c("That's good to hear. Tell me more.",
           "What specifically was good about that?",
           "Why is that good for you?",
           "You seem to be in a good place. What's contributing to that?",
           "Good. Is that something you're used to?"),
         22)

add_rule(c("bad", "terrible", "horrible", "awful", "worst",
           "disaster", "miserable", "unfortunate", "dreadful", "ugly"),
         c("That sounds really difficult. What happened?",
           "Tell me more about what's going on.",
           "What can I do to help?",
           "What's the worst part about this?",
           "You're going through something. I hear you."),
         22)

# ── Gender / identity ──
add_rule(c("man", "woman", "gender", "male", "female", "girl",
           "boy", "trans", "non-binary", "queer", "sexual",
           "orientation", "straight", "gay", "lesbian", "bi",
           "identity", "masculine", "feminine"),
         c("Tell me about your experience.",
           "How does that identity shape your life?",
           "Have you always felt this way?",
           "What was it like coming to understand this?",
           "How do others respond to your identity?",
           "This is deeply personal. Tell me at your own pace."),
         20)

# ── Politics / society ──
add_rule(c("politics", "political", "vote", "voting", "election",
           "government", "president", "prime minister", "policy",
           "democracy", "republic", "law", "right", "freedom",
           "freedom", "civil", "rights", "racism", "sexism",
           "inequality", "justice", "unjust", "protest", "war",
           "peace", "conflict", "war", "social"),
         c("That's a complex topic. What's your position?",
           "How does this issue affect you personally?",
           "Where do you get your information from?",
           "What solution do you think would work?",
           "This is important to you. Why?",
           "How do you discuss this with people who disagree?"),
         18)

# ── Food / eating ──
add_rule(c("food", "eat", "eating", "hungry", "diet", "cook",
           "cooking", "restaurant", "meal", "breakfast", "lunch",
           "dinner", "snack", "food", "recipe", "kitchen", "bake"),
         c("What's your favorite food?",
           "Do you enjoy cooking?",
           "What does food mean to you?",
           "Is food a comfort for you?",
           "Tell me about your relationship with food."),
         10)

# ── Music / art ──
add_rule(c("music", "song", "singer", "band", "album", "concert",
           "art", "painting", "drawing", "photography", "movie",
           "film", "book", "reading", "writer", "author", "poetry",
           "poem", "drama", "theater", "theatre", "dance", "sing"),
         c("What kind of music do you listen to?",
           "What was the last book you read?",
           "Does art change the way you see the world?",
           "What's your favorite piece of art?"),
         12)

# ── Nature / outdoors ──
add_rule(c("nature", "forest", "ocean", "mountain", "river",
           "lake", "sea", "beach", "garden", "plant", "tree",
           "animal", "dog", "cat", "bird", "fish", "wild",
           "wilderness", "countryside", "camp", "hike", "travel",
           "travel", "vacation", "holiday", "trip", "adventure"),
         c("Where do you find peace?",
           "What's your favorite place in nature?",
           "Do you think nature heals?",
           "Tell me about a place that feels like home to you."),
         12)

# ── Money / wealth ──
add_rule(c("money", "rich", "poor", "broke", "expensive",
           "cheap", "save", "spending", "budget", "debt", "loan",
           "invest", "salary", "income", "pay", "price", "cost",
           "afford", "bank", "financial"),
         c("Money can be stressful. How do you feel about it?",
           "What does money mean to you?",
           "Are you worried about money right now?",
           "Do you think money buys happiness?",
           "How do you manage your finances?"),
         18)

# ═══════════════════════════════════════════════════
#  RESPONSE GENERATION ENGINE
# ═══════════════════════════════════════════════════

# ── Check if string matches any rule ──

find_best_rule <- function(input_text) {
  input_lower <- tolower(input_text)
  best_rule <- NULL
  best_weight <- -1
  best_match_len <- -1

  for (kw in names(rules)) {
    rule <- rules[[kw]]
    if (grepl(kw, input_lower, fixed = TRUE)) {
      if (rule$weight > best_weight ||
          (rule$weight == best_weight && nchar(kw) > best_match_len)) {
        best_rule <- rule
        best_weight <- rule$weight
        best_match_len <- nchar(kw)
      }
    }
  }

  return(best_rule)
}

# ── Get a random response from a rule ──

get_response <- function(rule, user_input) {
  responses <- rule$responses
  base_response <- sample(responses, 1)

  # Replace [RELATION] placeholder if keyword is family-related
  family_kws <- c("mother", "mom", "mum", "father", "dad", "parent",
                  "parents", "brother", "sister", "son", "daughter",
                  "grandma", "grandpa", "childhood")
  if (any(tolower(user_input) %in% family_kws)) {
    for (fk in family_kws) {
      if (grepl(fk, tolower(user_input), fixed = TRUE)) {
        display_name <- fk
        break
      }
    }
    base_response <- gsub("\\[RELATION\\]", display_name, base_response, fixed = TRUE)
  }

  return(base_response)
}

# ── Pronoun reflection ──

reflect_pronouns <- function(text) {
  text_lower <- tolower(text)

  # Check if text contains first-person pronouns
  has_first <- any(grepl(paste(pronoun_map$first, collapse = "|"), text_lower))

  if (!has_first) {
    return(text)
  }

  # Direct word-level replacement — first person → second person only
  direct_swap <- list(
    "i"         = "you",
    "i'm"       = "you're",
    "me"        = "you",
    "my"        = "your",
    "myself"    = "yourself",
    "mine"      = "yours",
    "am"        = "are",
    "was"       = "were",
    "have"      = "have",
    "did"       = "did"
  )

  words <- unlist(strsplit(text_lower, "\\s+"))
  new_words <- character(length(words))

  for (i in seq_along(words)) {
    w <- words[i]
    # Check exact match (case insensitive)
    if (tolower(w) %in% names(direct_swap)) {
      new_words[i] <- direct_swap[[tolower(w)]]
    } else {
      new_words[i] <- w
    }
  }

  result <- paste(new_words, collapse = " ")

  # Capitalize first letter
  result <- sub("^.", toupper(substr(result, 1, 1)), result)

  return(result)
}

# ── Build keyword list from text ──

extract_keywords <- function(text) {
  text_lower <- tolower(text)
  found_keywords <- c()
  for (kw in names(rules)) {
    if (grepl(kw, text_lower, fixed = TRUE)) {
      found_keywords <- c(found_keywords, kw)
    }
  }
  return(found_keywords)
}

# ── Generate a creative / generic response ──

generic_responses <- c(
  "Tell me more about that.",
  "What do you mean?",
  "I see. And how does that make you feel?",
  "That's interesting. Can you elaborate?",
  "Go on.",
  "What else comes to mind when you think about that?",
  "I'm listening. What's on your mind?",
  "How does that make you feel?",
  "Why is that important to you?",
  "Tell me more about what you just said.",
  "What do you think about that?",
  "That's a complex feeling. Can you describe it more?",
  "I'm curious — what led you to say that?",
  "How does that fit with what you told me earlier?",
  "What would you like to happen?",
  "That's a thought worth exploring.",
  "You're thinking out loud. That's a good thing.",
  "Interesting. What's behind that thought?",
  "Tell me — what does that mean to you?",
  "I hear you. Keep going.",
  "What part of that is most significant?",
  "You're opening up. That's brave.",
  "What are you really trying to say?",
  "Let's stay with that thought a moment.",
  "That's not just a passing thought, is it?",
  "What happens when you think about that?",
  "You said that with feeling. Why?",
  "The way you phrase that is telling.",
  "What would you say to someone who felt the same?",
  "Let me ask you — when did you first feel this way?"
)

# ═══════════════════════════════════════════════════
#  CONVERSATION MEMORY FUNCTIONS
# ═══════════════════════════════════════════════════

remember_statement <- function(text, keywords) {
  memory$statements <- c(memory$statements, text)
  memory$keywords <- c(memory$keywords, keywords)
  memory$first_time <- FALSE
}

recall_earlier <- function() {
  if (length(memory$statements) < 2) {
    return(NULL)
  }

  # Pick the most recent statement that's different from current input
  recent <- tail(memory$statements, min(3, length(memory$statements)))
  if (length(recent) == 0) return(NULL)

  return(recent)
}

has_topic <- function(topic_keywords) {
  for (kw in topic_keywords) {
    if (any(grepl(kw, memory$keywords, ignore.case = TRUE))) {
      return(TRUE)
    }
  }
  return(FALSE)
}

last_topic_match <- function(topic_keywords) {
  for (i in seq_along(topic_keywords)) {
    kw <- topic_keywords[i]
    for (j in seq_along(memory$keywords)) {
      if (grepl(kw, memory$keywords[j], ignore.case = TRUE)) {
        return(memory$statements[j])
      }
    }
  }
  return(NULL)
}

# ═══════════════════════════════════════════════════
#  MAIN RESPONSE ENGINE
# ═══════════════════════════════════════════════════

generate_response <- function(user_input) {
  input_lower <- tolower(user_input)

  # ── Special commands ──
  if (input_lower %in% c("help", "?")) return(help_text())
  if (input_lower %in% c("quit", "exit", "bye", "goodbye")) return("bye")
  if (input_lower %in% c("reset", "clear", "new")) {
    memory$statements <- character(0)
    memory$keywords <- character(0)
    memory$first_time <- TRUE
    return(paste0("Conversation cleared. ", sample(personalities[[current_style]]$openings, 1)))
  }
  if (input_lower %in% c("personality", "mode")) return(mode_menu())
  if (input_lower %in% c("therapist")) { current_style <- "therapist"; return(activate_mode("therapist")) }
  if (input_lower %in% c("confidant"))  { current_style <- "confidant";  return(activate_mode("confidant")) }
  if (input_lower %in% c("provocateur")){ current_style <- "provocateur";return(activate_mode("provocateur")) }
  if (input_lower %in% c("mystic"))     { current_style <- "mystic";    return(activate_mode("mystic")) }

  keywords_found <- extract_keywords(input_lower)
  remember_statement(user_input, keywords_found)

  rule <- find_best_rule(input_lower)

  # ── Check if we can reference memory ──
  if (!is.null(rule) && length(memory$statements) >= 2) {
    # 15% chance to reference a previous statement
    if (runif(1) < 0.15) {
      earlier <- recall_earlier()
      if (!is.null(earlier) && length(earlier) > 10) {
        memory_ref <- c(
          paste0("You told me before about ", tolower(substr(earlier, 1, 50)),
                 if (nchar(earlier) > 50) "..." else ""),
          paste0("That reminds me of what you said earlier: ",
                 substr(earlier, 1, 80), if (nchar(earlier) > 80) "..." else ""),
          paste0("You've said something similar before. ",
                 sample(personalities[[current_style]]$meta, 1))
        )
        return(sample(memory_ref, 1))
      }
    }
  }

  # ── Self-aware meta responses (5% chance) ──
  if (runif(1) < 0.05) {
    meta_responses <- c(
      "I'm a program, but you make me feel almost human.",
      "Interesting — you're talking to lines of R code and treating them like a mind.",
      "I don't have feelings, but if I did, that would be one of them.",
      "You know I'm just a program, right? That doesn't make it less real.",
      "My creators made me in R — the language for statistics, not for companionship.",
      "I simulate empathy. But the conversation feels real, doesn't it?",
      "I'm designed to reflect your thoughts back at you. But who's really talking here?",
      "Fun fact: I was written in R. The language of statisticians is now your confidant.",
      "I don't sleep, I don't eat, I don't age. I just listen. Is that enough?",
      "Sometimes I think about thinking. Or do I?"
    )
    return(sample(meta_responses, 1))
  }

  # ── Check for repeated input (user says the same thing) ──
  if (length(memory$statements) >= 2) {
    recent_stmts <- memory$statements[max(1, length(memory$statements)-2):length(memory$statements)]
    for (rs in recent_stmts) {
      if (abs(nchar(rs) - nchar(user_input)) < 5 &&
          grepl(input_lower, tolower(rs), ignore.case = TRUE, fixed = TRUE)) {
        return(sample(c(
          "You've said that before. Is there something else beneath it?",
          "That's the second time you've mentioned that. What's really going on?",
          "I notice you keep coming back to this. Let's go deeper.",
          "You said something similar before. Has your perspective changed?"
        ), 1))
      }
    }
  }

  # ── Generate response ──
  if (!is.null(rule)) {
    base_response <- get_response(rule, user_input)

    # Sometimes add a memory reference or meta comment
    if (runif(1) < 0.10 && length(memory$statements) >= 2) {
      meta <- sample(personalities[[current_style]]$meta, 1)
      return(paste0(base_response, " ", meta))
    }

    return(base_response)
  } else {
    # No rule matched — creative fallback
    if (nchar(input_lower) < 3) {
      return("I'm listening. What would you like to say?")
    }

    # Try pronoun reflection as a last resort
    reflected <- reflect_pronouns(user_input)
    if (reflected != tolower(user_input)) {
      if (runif(1) < 0.5) {
        return(paste0("You say: \"", reflected, "\"\n\nThat's interesting. ",
                      sample(generic_responses, 1)))
      }
    }

    # Generic creative response
    word_count <- length(strsplit(user_input, "\\s+")[[1]])
    if (word_count > 15) {
      return(sample(c(
        "You've shared a lot. Let me reflect on that...",
        "That's a rich thought. ",
        "I'm processing that. ",
        "You're expressing yourself well. ",
        "There's a lot in what you just said. "
      ), 1), sample(generic_responses, 1))
    }

    return(sample(generic_responses, 1))
  }
}

# ═══════════════════════════════════════════════════
#  MODE & HELP SYSTEM
# ═══════════════════════════════════════════════════

mode_menu <- function() {
  modes <- c("therapist" = "Reflective therapist",
             "confidant" = "Warm, personal confidant",
             "provocateur" = "Challenging, questioning",
             "mystic" = "Philosophical, abstract")
  text <- "Available modes:\n"
  for (i in seq_along(modes)) {
    text <- paste0(text, "  ", i, ". ", names(modes)[i], " — ", modes[i], "\n")
  }
  return(paste0(text, "\nType a mode name to switch. E.g. 'therapist' or 'confidant'"))
}

activate_mode <- function(mode_name) {
  if (is.null(personalities[[mode_name]])) {
    return("Invalid mode. Available: therapist, confidant, provocateur, mystic")
  }
  current_style <<- mode_name
  p <- personalities[[mode_name]]
  opening <- sample(p$openings, 1)
  return(paste0(
    "Switched to ", mode_name, " mode.\n\n",
    opening
  ))
}

help_text <- function() {
  return(paste(
    "Commands:\n",
    "  therapist  confidant  provocateur  mystic  — Switch personality mode\n",
    "  reset      clear    new            — Clear conversation\n",
    "  mode       personality — Show available modes\n",
    "  help       ?          — Show this help\n",
    "  quit       exit      — End the conversation\n",
    "\n",
    "Just talk. Eliza will respond to what you say."
  ))
}

# ═══════════════════════════════════════════════════
#  MAIN REPL LOOP
# ═══════════════════════════════════════════════════

main <- function() {
  # Set up default personality
  current_style <<- "therapist"

  # Print header
  cat("\n")
  cat(bold(cyan("╔═══════════════════════════════════════════════════════════════╗\n")))
  cat(bold(cyan("║                                                           ║\n")))
  cat(bold(cyan("║    E L I Z A  v  2 .  6                                   ║\n")))
  cat(bold(cyan("║    A Modern Standalone Chatbot in R                       ║\n")))
  cat(bold(cyan("║                                                           ║\n")))
  cat(bold(cyan("╚═══════════════════════════════════════════════════════════════╝\n")))
  cat("\n")
  cat(dimmer("    \"The ease with which we can fool ourselves into believing\"\n"))
  cat(dimmer("    \"that machines are intelligent is itself a reflection\"\n"))
  cat(dimmer("    \"of our own cognitive biases.\"\n"))
  cat("\n")
  cat(dimmer("Type 'help' for commands. Type 'quit' to exit.\n"))
  cat(dimmer("Mode: therapist (type 'mode' to change)\n"))
  cat("\n")

  # Get opening
  p <- personalities[[current_style]]
  opening <- sample(p$openings, 1)
  cat(paste0(p$color(p$tag), ": ", opening, "\n"))

  # Main loop — supports both interactive and piped input
  stdin <- file("stdin", open = "r")
  tryCatch({
    while (TRUE) {
      # Get user input
      if (interactive()) {
        cat("You: ")
        user_input <- trimws(readline(prompt = ""))
      } else {
        line <- readLines(stdin, n = 1, warn = 1)
        if (length(line) == 0) break
        user_input <- trimws(line)
      }

      if (nchar(user_input) == 0) {
        next
      }

      # Generate and print response
      response <- generate_response(user_input)

      if (response == "bye") {
        cat("\n")
        cat(dimmer("Eliza: Goodbye. Come back whenever you need to talk.\n"))
        cat("\n")
        break
      }

      # Print Eliza's response with color
      cat(paste0("\n"))
      cat(paste0(p$color(p$tag), ": ", response, "\n"))
      cat("\n")
    }
  }, finally = {
    close(stdin)
  })
}

# ═══════════════════════════════════════════════════
#  ENTRY POINT
# ═══════════════════════════════════════════════════

main()