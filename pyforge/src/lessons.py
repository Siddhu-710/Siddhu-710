# PyForge course content. build.py runs every solution with CPython to fill in `expected`.
L = []

def lesson(**kw):
    kw.setdefault("stdin", "")
    kw.setdefault("check", "exact")
    L.append(kw)

# =============================== BEGINNER ===============================
lesson(id="b1", level="Beginner", mins=8, title="Your first program",
body="""
<p>A Python program is a text file of instructions that run from top to bottom. The first instruction most people learn is <code>print()</code>, which shows text on the screen.</p>
<ul>
<li>Text goes inside quotes: <code>"hello"</code> or <code>'hello'</code>. Text in quotes is called a <b>string</b>.</li>
<li><code>print()</code> can take several items separated by commas, and puts a space between them.</li>
<li>Anything after <code>#</code> on a line is a <b>comment</b>. Python skips it; people read it.</li>
<li><code>\\n</code> inside a string means "new line".</li>
</ul>
<p>Python is case-sensitive: <code>Print("hi")</code> fails because the function is called <code>print</code>.</p>
<div class="note"><b>Common mistake:</b> forgetting a closing quote or bracket. Python then reports a <code>SyntaxError</code> and points at the line.</div>
""",
example='''# This is a comment. Python ignores it.
print("Hello, PyForge!")
print("Python", "is", "fun")      # items are joined with spaces
print("Line one\\nLine two")        # \\n starts a new line
print(2026)                        # numbers need no quotes''',
task="Print exactly two lines: <code>Hello, World!</code> and then <code>I am learning Python.</code>",
starter='# Write your two print statements below\n',
hint='Use print() twice, one for each line. Watch the comma and the full stop.',
solution='print("Hello, World!")\nprint("I am learning Python.")')

lesson(id="b2", level="Beginner", mins=10, title="Variables and data types",
body="""
<p>A <b>variable</b> is a name that points to a value. You create one with <code>=</code>, which means "store", not "equals".</p>
<pre><code>name = "Asha"      # str   (text)
age = 21           # int   (whole number)
height = 1.62      # float (decimal number)
is_student = True  # bool  (True or False)</code></pre>
<ul>
<li>Names may use letters, digits and <code>_</code>, but can't start with a digit. Use <code>snake_case</code>.</li>
<li><code>type(x)</code> tells you what kind of value <code>x</code> holds.</li>
<li>You can re-assign a variable at any time, even to a different type.</li>
</ul>
<div class="note"><b>Tip:</b> choose names that say what the value means: <code>price</code> beats <code>p</code>.</div>
""",
example='''name = "Asha"
age = 21
height = 1.62
is_student = True
print(name, age, height, is_student)
print(type(name), type(age), type(height), type(is_student))
age = age + 1          # re-assign using the old value
print("Next year:", age)''',
task="Create <code>name = \"Ravi\"</code> and <code>age = 25</code>. Print <code>Ravi is 25 years old</code>, then print the type of <code>age</code>.",
starter='name = \nage = \n',
hint='print(name, "is", age, "years old") then print(type(age))',
solution='name = "Ravi"\nage = 25\nprint(name, "is", age, "years old")\nprint(type(age))')

lesson(id="b3", level="Beginner", mins=10, title="Numbers and math",
body="""
<p>Python is a very good calculator. These are the arithmetic operators:</p>
<table class="ref"><tr><th>Operator</th><th>Meaning</th><th>Example</th><th>Result</th></tr>
<tr><td><code>+ - *</code></td><td>add, subtract, multiply</td><td><code>3 * 4</code></td><td>12</td></tr>
<tr><td><code>/</code></td><td>true division (always float)</td><td><code>7 / 2</code></td><td>3.5</td></tr>
<tr><td><code>//</code></td><td>floor division</td><td><code>7 // 2</code></td><td>3</td></tr>
<tr><td><code>%</code></td><td>remainder (modulo)</td><td><code>7 % 2</code></td><td>1</td></tr>
<tr><td><code>**</code></td><td>power</td><td><code>2 ** 10</code></td><td>1024</td></tr></table>
<p>Order of operations follows maths rules: brackets first, then <code>**</code>, then <code>* / // %</code>, then <code>+ -</code>. <code>round(x, 2)</code> rounds to 2 decimal places, <code>abs(x)</code> removes the sign.</p>
<div class="note"><b>Floats are approximate:</b> <code>0.1 + 0.2</code> gives <code>0.30000000000000004</code>. Round before you display money.</div>
""",
example='''print(7 / 2, 7 // 2, 7 % 2, 2 ** 10)
print((2 + 3) * 4)
print(round(3.14159, 2), abs(-8))
price = 499
qty = 3
print("Total:", price * qty)
counter = 10
counter += 5       # same as counter = counter + 5
print(counter)''',
task="Given <code>total = 17</code> and <code>people = 5</code>, print on three lines: the floor division, the remainder, and the true division.",
starter='total = 17\npeople = 5\n',
hint='Use //, % and / in three print() calls.',
solution='total = 17\npeople = 5\nprint(total // people)\nprint(total % people)\nprint(total / people)')

lesson(id="b4", level="Beginner", mins=12, title="Working with strings",
body="""
<p>Strings are sequences of characters. Each character has a position (an <b>index</b>) that starts at <code>0</code>. Negative indexes count from the end.</p>
<pre><code>word = "python"
word[0]     # 'p'
word[-1]    # 'n'
word[1:4]   # 'yth'   (slice: start up to, not including, end)
len(word)   # 6</code></pre>
<p>Strings have <b>methods</b>: <code>.upper()</code>, <code>.lower()</code>, <code>.title()</code>, <code>.strip()</code>, <code>.replace(a, b)</code>, <code>.split()</code>, <code>.count(x)</code>, <code>.startswith(x)</code>. Strings can't be changed in place; methods return a new string.</p>
<p>An <b>f-string</b> puts values inside text: <code>f"Hi {name}, you are {age}"</code>.</p>
""",
example='''word = "python"
print(word[0], word[-1], word[1:4], len(word))
print(word.upper(), word.title())
sentence = "  learn python step by step  "
print(sentence.strip())
print(sentence.split())
print("py" in word)
name, lessons = "Mira", 4
print(f"{name} finished {lessons} lessons")''',
task="With <code>word = \"programming\"</code>, print on separate lines: its length, its first letter, its last 4 letters, and the word in capitals.",
starter='word = "programming"\n',
hint='len(word), word[0], word[-4:], word.upper()',
solution='word = "programming"\nprint(len(word))\nprint(word[0])\nprint(word[-4:])\nprint(word.upper())')

lesson(id="b5", level="Beginner", mins=10, title="Input and type conversion", check="contains",
stdin="7\n5",
body="""
<p><code>input()</code> pauses the program and reads one line typed by the user. It <b>always returns a string</b>, even if the user types a number.</p>
<pre><code>age = input("Age? ")      # "21"  (a str)
age = int(age)            # 21    (an int)</code></pre>
<p>Conversion functions: <code>int()</code>, <code>float()</code>, <code>str()</code>, <code>bool()</code>. Converting text that isn't a number, like <code>int("abc")</code>, raises a <code>ValueError</code>. You will learn to handle that in the Error handling lesson.</p>
<div class="note"><b>In PyForge:</b> type the values your program should read into the <b>Input</b> box, one per line, before you press Run.</div>
""",
example='''name = input("What is your name? ")
print("Nice to meet you,", name)
year = int(input("Birth year? "))
print("In 2030 you will be", 2030 - year)''',
example_stdin="Sita\n2004",
task="Read two whole numbers with <code>input()</code> (the Input box already holds <code>7</code> and <code>5</code>) and print <code>Sum: 12</code> using their real sum.",
starter='a = input()\nb = input()\n',
hint='Convert both with int() before adding, then print(f"Sum: {a + b}")',
solution='a = int(input())\nb = int(input())\nprint(f"Sum: {a + b}")',
expected="Sum: 12")

lesson(id="b6", level="Beginner", mins=12, title="Making decisions with if",
body="""
<p><code>if</code> runs a block of code only when a condition is <code>True</code>. The block is marked by <b>indentation</b> (4 spaces) after a colon.</p>
<pre><code>if temperature &gt; 30:
    print("Hot")
elif temperature &gt; 20:
    print("Warm")
else:
    print("Cool")</code></pre>
<ul>
<li>Comparisons: <code>==</code> <code>!=</code> <code>&lt;</code> <code>&gt;</code> <code>&lt;=</code> <code>&gt;=</code></li>
<li>Combine with <code>and</code>, <code>or</code>, <code>not</code>.</li>
<li>Python checks <code>elif</code> branches top to bottom and runs only the first that matches.</li>
</ul>
<div class="note"><b>Common mistake:</b> using <code>=</code> (store) instead of <code>==</code> (compare) inside a condition.</div>
""",
example='''temperature = 26
if temperature > 30:
    print("Hot")
elif temperature > 20:
    print("Warm")
else:
    print("Cool")

age, has_ticket = 19, True
if age >= 18 and has_ticket:
    print("Welcome in")
if not has_ticket:
    print("Buy a ticket first")''',
task="With <code>score = 82</code>, print <code>Grade: A</code> for 90+, <code>Grade: B</code> for 75+, <code>Grade: C</code> for 60+, otherwise <code>Grade: F</code>.",
starter='score = 82\n',
hint='Order matters: test the highest boundary first with if, then elif, elif, else.',
solution='score = 82\nif score >= 90:\n    print("Grade: A")\nelif score >= 75:\n    print("Grade: B")\nelif score >= 60:\n    print("Grade: C")\nelse:\n    print("Grade: F")')

lesson(id="b7", level="Beginner", mins=14, title="Loops: for and while",
body="""
<p>A <b>loop</b> repeats code. <code>for</code> walks through every item of a sequence; <code>range()</code> makes a sequence of numbers.</p>
<pre><code>range(5)        # 0 1 2 3 4
range(1, 6)     # 1 2 3 4 5
range(0, 10, 2) # 0 2 4 6 8</code></pre>
<p><code>while</code> repeats as long as a condition stays true. Make sure something inside the loop changes the condition, or it runs forever.</p>
<ul><li><code>break</code> leaves the loop immediately.</li><li><code>continue</code> skips to the next round.</li></ul>
""",
example='''for i in range(1, 4):
    print("Round", i)

for letter in "abc":
    print(letter.upper())

count = 3
while count > 0:
    print("Countdown", count)
    count -= 1

for n in range(10):
    if n == 5:
        break
    if n % 2 == 0:
        continue
    print("odd:", n)''',
task="Print the 7 times table from 1 to 5, one line each, in the form <code>7 x 1 = 7</code>.",
starter='for i in range(1, 6):\n    pass\n',
hint='Inside the loop: print(f"7 x {i} = {7 * i}")',
solution='for i in range(1, 6):\n    print(f"7 x {i} = {7 * i}")')

lesson(id="b8", level="Beginner", mins=14, title="Lists",
body="""
<p>A <b>list</b> holds many values in order: <code>marks = [72, 88, 95]</code>. Lists can grow, shrink and change.</p>
<table class="ref"><tr><th>Action</th><th>Code</th></tr>
<tr><td>Read / change an item</td><td><code>marks[0]</code>, <code>marks[0] = 75</code></td></tr>
<tr><td>Add to the end / insert</td><td><code>marks.append(60)</code>, <code>marks.insert(0, 50)</code></td></tr>
<tr><td>Remove</td><td><code>marks.remove(88)</code>, <code>marks.pop()</code></td></tr>
<tr><td>Sort</td><td><code>marks.sort()</code> (in place) or <code>sorted(marks)</code> (new list)</td></tr>
<tr><td>Measure</td><td><code>len()</code>, <code>sum()</code>, <code>min()</code>, <code>max()</code></td></tr></table>
<p>Loop over a list with <code>for m in marks:</code>. Use <code>enumerate(marks)</code> when you also need the position.</p>
""",
example='''fruits = ["mango", "apple", "banana"]
fruits.append("kiwi")
fruits.sort()
print(fruits, len(fruits))
for i, fruit in enumerate(fruits, start=1):
    print(i, fruit)
nums = [4, 8, 15, 16, 23, 42]
print(sum(nums), min(nums), max(nums))
print(nums[:3], nums[-2:])''',
task="Start with <code>marks = [72, 88, 95, 60, 81]</code>. Append <code>90</code>, then print the sorted list, the highest mark, and the average rounded to 1 decimal place.",
starter='marks = [72, 88, 95, 60, 81]\n',
hint='average = sum(marks) / len(marks); print(round(average, 1))',
solution='marks = [72, 88, 95, 60, 81]\nmarks.append(90)\nprint(sorted(marks))\nprint(max(marks))\nprint(round(sum(marks) / len(marks), 1))')

lesson(id="b9", level="Beginner", mins=15, title="Dictionaries, tuples and sets",
body="""
<p>A <b>dictionary</b> maps keys to values. It is the shape JSON data from an API takes in Python.</p>
<pre><code>student = {"name": "Mira", "level": 3}
student["name"]            # 'Mira'
student["email"] = "m@x.io" # add or update
student.get("age", 0)      # 0 when the key is missing</code></pre>
<p>Loop with <code>for key, value in student.items():</code>. Since Python 3.7, dictionaries keep insertion order.</p>
<ul>
<li><b>Tuple</b> <code>(3, 4)</code>: like a list but can't be changed. Good for fixed records and returning two values.</li>
<li><b>Set</b> <code>{"a", "b"}</code>: unordered, no duplicates. <code>set(list)</code> removes repeats; supports <code>|</code> union and <code>&amp;</code> intersection.</li>
</ul>
""",
example='''student = {"name": "Mira", "level": 3}
student["email"] = "mira@example.com"
for key, value in student.items():
    print(key, "->", value)
print(student.get("age", "unknown"))

point = (3, 4)
x, y = point           # unpacking
print(x + y)

tags = ["python", "api", "python", "web"]
print(sorted(set(tags)))
print({"a", "b"} & {"b", "c"})''',
task="Start with <code>stock = {\"apple\": 5, \"banana\": 0, \"mango\": 12}</code>. Add <code>\"grape\": 7</code>. Print every fruit with quantity above 0 as <code>apple: 5</code>, then print <code>Total: 24</code> using the real total.",
starter='stock = {"apple": 5, "banana": 0, "mango": 12}\n',
hint='Loop with for fruit, qty in stock.items(): and use sum(stock.values()) for the total.',
solution='stock = {"apple": 5, "banana": 0, "mango": 12}\nstock["grape"] = 7\nfor fruit, qty in stock.items():\n    if qty > 0:\n        print(f"{fruit}: {qty}")\nprint(f"Total: {sum(stock.values())}")')

# ============================= INTERMEDIATE =============================
lesson(id="i1", level="Intermediate", mins=14, title="Functions",
body="""
<p>A <b>function</b> is a named, reusable block of code. <code>def</code> creates it; <code>return</code> sends a value back to the caller.</p>
<pre><code>def area(width, height=1):
    \"\"\"Return the area of a rectangle.\"\"\"
    return width * height</code></pre>
<ul>
<li><b>Parameters</b> are the names in the definition; <b>arguments</b> are the values you pass.</li>
<li>A <b>default value</b> (<code>height=1</code>) makes an argument optional.</li>
<li>Arguments can be passed by name: <code>area(height=2, width=5)</code>.</li>
<li>A function without <code>return</code> gives back <code>None</code>.</li>
</ul>
<div class="note"><b>Rule of thumb:</b> one function, one job. If you can't name it simply, split it.</div>
""",
example='''def greet(name, greeting="Hello"):
    """Build a greeting message."""
    return f"{greeting}, {name}!"

print(greet("Asha"))
print(greet("Leo", greeting="Namaste"))

def stats(numbers):
    return min(numbers), max(numbers)   # return a tuple

low, high = stats([4, 9, 1, 7])
print(low, high)''',
task="Write <code>area(w, h=1)</code> that returns <code>w * h</code>. Print <code>area(4, 5)</code> and then <code>area(7)</code>.",
starter='def area(w, h=1):\n    pass\n\n',
hint='Replace pass with return w * h, then call print(area(4, 5)) and print(area(7)).',
solution='def area(w, h=1):\n    return w * h\n\nprint(area(4, 5))\nprint(area(7))')

lesson(id="i2", level="Intermediate", mins=14, title="*args, **kwargs and scope",
body="""
<p><code>*args</code> collects any number of positional arguments into a tuple. <code>**kwargs</code> collects named arguments into a dictionary.</p>
<pre><code>def log(*args, **kwargs):
    print(args)    # (1, 2)
    print(kwargs)  # {'level': 'info'}
log(1, 2, level="info")</code></pre>
<p><b>Scope</b> decides where a name is visible. Variables created inside a function are <b>local</b> and vanish when it returns. Code inside a function can read global names, but to reassign one it needs <code>global name</code>. Needing <code>global</code> often is a sign the value should be a parameter or a return value instead.</p>
<p>The <code>*</code> also <b>unpacks</b>: <code>print(*[1, 2, 3])</code> is the same as <code>print(1, 2, 3)</code>.</p>
""",
example='''def average(*nums):
    return sum(nums) / len(nums) if nums else 0

print(average(4, 8, 6))

def make_tag(tag, text, **attrs):
    extra = "".join(f' {k}="{v}"' for k, v in attrs.items())
    return f"<{tag}{extra}>{text}</{tag}>"

print(make_tag("a", "Docs", href="/docs", target="_blank"))

total = 0
def add(n):
    global total
    total += n
add(5); add(10)
print(total)''',
task="Write <code>total(*nums)</code> returning the sum, and <code>profile(**info)</code> that prints each <code>key=value</code> pair in alphabetical key order. Print <code>total(1, 2, 3, 4)</code>, then call <code>profile(name=\"Mira\", level=\"Pro\")</code>.",
starter='def total(*nums):\n    pass\n\ndef profile(**info):\n    pass\n\n',
hint='for key in sorted(info): print(f"{key}={info[key]}")',
solution='def total(*nums):\n    return sum(nums)\n\ndef profile(**info):\n    for key in sorted(info):\n        print(f"{key}={info[key]}")\n\nprint(total(1, 2, 3, 4))\nprofile(name="Mira", level="Pro")')

lesson(id="i3", level="Intermediate", mins=12, title="Comprehensions",
body="""
<p>A <b>comprehension</b> builds a list, dict or set in one readable line.</p>
<pre><code>[expression for item in iterable if condition]
{key: value for item in iterable}
{expression for item in iterable}</code></pre>
<p>This loop:</p>
<pre><code>squares = []
for n in range(5):
    squares.append(n * n)</code></pre>
<p>becomes <code>squares = [n * n for n in range(5)]</code>.</p>
<div class="note"><b>Keep them short.</b> If a comprehension needs two conditions and nested loops, a normal loop is easier to read.</div>
""",
example='''names = ["asha", "leo", "mira"]
print([n.title() for n in names])
print([n for n in names if len(n) > 3])
lengths = {n: len(n) for n in names}
print(lengths)
print({ch for ch in "mississippi"} == set("misp"))
grid = [[r * 3 + c for c in range(3)] for r in range(2)]
print(grid)''',
task="From the numbers 1 to 10, print a list of the squares of the even numbers. Then print a dict mapping 1, 2, 3 to their cubes.",
starter='nums = range(1, 11)\n',
hint='[n ** 2 for n in nums if n % 2 == 0] and {n: n ** 3 for n in range(1, 4)}',
solution='nums = range(1, 11)\nprint([n ** 2 for n in nums if n % 2 == 0])\nprint({n: n ** 3 for n in range(1, 4)})')

lesson(id="i4", level="Intermediate", mins=14, title="Handling errors",
body="""
<p>When something goes wrong, Python <b>raises an exception</b>. Without handling, the program stops and prints a traceback. <code>try</code>/<code>except</code> lets you recover.</p>
<pre><code>try:
    n = int(text)
except ValueError:
    print("Not a number")
else:
    print("Parsed", n)       # only when no error
finally:
    print("Always runs")</code></pre>
<ul>
<li>Catch <b>specific</b> exceptions (<code>ValueError</code>, <code>KeyError</code>, <code>ZeroDivisionError</code>, <code>FileNotFoundError</code>), not a bare <code>except:</code>.</li>
<li><code>raise ValueError("amount must be positive")</code> signals a problem yourself.</li>
<li><code>except Exception as e:</code> gives you the error object; <code>str(e)</code> is its message.</li>
</ul>
""",
example='''def parse_age(text):
    try:
        age = int(text)
    except ValueError:
        return "Please enter digits only"
    if age < 0:
        raise ValueError("age can't be negative")
    return age

print(parse_age("21"))
print(parse_age("twenty"))
try:
    parse_age("-4")
except ValueError as e:
    print("Error:", e)

data = {"a": 1}
try:
    print(data["b"])
except KeyError as e:
    print("Missing key", e)''',
task="Write <code>safe_divide(a, b)</code> that returns <code>a / b</code>, or the text <code>Cannot divide by zero</code> when <code>b</code> is 0. Print <code>safe_divide(10, 4)</code> and <code>safe_divide(1, 0)</code>. Then try <code>int(\"abc\")</code> and print <code>Invalid number</code> when it fails.",
starter='def safe_divide(a, b):\n    pass\n\n',
hint='Wrap return a / b in try, and catch ZeroDivisionError. Catch ValueError around int("abc").',
solution='def safe_divide(a, b):\n    try:\n        return a / b\n    except ZeroDivisionError:\n        return "Cannot divide by zero"\n\nprint(safe_divide(10, 4))\nprint(safe_divide(1, 0))\ntry:\n    int("abc")\nexcept ValueError:\n    print("Invalid number")')

lesson(id="i5", level="Intermediate", mins=12, title="Modules and the standard library",
body="""
<p>A <b>module</b> is a file of Python code you can reuse. Python ships with a large <b>standard library</b>, so many tools are one <code>import</code> away.</p>
<pre><code>import math                  # use as math.sqrt(9)
from datetime import date    # use as date.today()
import statistics as st      # short alias</code></pre>
<table class="ref"><tr><th>Module</th><th>Use it for</th></tr>
<tr><td><code>math</code></td><td>sqrt, pi, floor, ceil, trig</td></tr>
<tr><td><code>random</code></td><td>random numbers, shuffle, choice</td></tr>
<tr><td><code>datetime</code></td><td>dates, times, durations</td></tr>
<tr><td><code>json</code></td><td>read and write JSON text</td></tr>
<tr><td><code>statistics</code></td><td>mean, median, stdev</td></tr>
<tr><td><code>os</code>, <code>pathlib</code></td><td>files and folders</td></tr></table>
<p>Third-party packages (like <code>requests</code> or <code>flask</code>) are installed with <code>pip install name</code> on your own computer.</p>
""",
example='''import math
import random
from datetime import date, timedelta
import statistics as st

print(math.sqrt(81), math.floor(4.7), math.ceil(4.2))
print(random.choice(["red", "green", "blue"]))
start = date(2026, 9, 1)
print(start + timedelta(days=30))
print(st.mean([3, 5, 10]), st.median([3, 5, 10]))''',
task="Print on three lines: the square root of 144, pi rounded to 3 decimal places, and the weekday name of 1 January 2026 (use <code>strftime(\"%A\")</code>).",
starter='import math\nfrom datetime import date\n',
hint='math.sqrt(144), round(math.pi, 3), date(2026, 1, 1).strftime("%A")',
solution='import math\nfrom datetime import date\nprint(math.sqrt(144))\nprint(round(math.pi, 3))\nprint(date(2026, 1, 1).strftime("%A"))')

lesson(id="i6", level="Intermediate", mins=14, title="Formatting output and JSON",
body="""
<p>f-strings accept a <b>format spec</b> after a colon:</p>
<table class="ref"><tr><th>Spec</th><th>Example</th><th>Result</th></tr>
<tr><td><code>.2f</code></td><td><code>f"{3.14159:.2f}"</code></td><td>3.14</td></tr>
<tr><td><code>,</code></td><td><code>f"{1234567:,}"</code></td><td>1,234,567</td></tr>
<tr><td><code>&lt;8</code> / <code>&gt;8</code> / <code>^8</code></td><td><code>f"{'id':&gt;5}"</code></td><td>&nbsp;&nbsp;&nbsp;id</td></tr>
<tr><td><code>%</code></td><td><code>f"{0.875:.0%}"</code></td><td>88%</td></tr></table>
<p><b>JSON</b> is the text format almost every web API speaks. The <code>json</code> module converts between JSON text and Python objects:</p>
<pre><code>json.dumps({"ok": True})     # '{"ok": true}'   dict -&gt; text
json.loads('{"ok": true}')   # {'ok': True}     text -&gt; dict</code></pre>
""",
example='''import json
price, qty = 24.5, 3
print(f"{'Item':<8}{'Qty':>4}{'Total':>9}")
print(f"{'Bag':<8}{qty:>4}{price * qty:>9.2f}")
print(f"{1234567:,} downloads, {0.875:.0%} success")

order = {"id": 17, "items": ["pen", "ink"], "paid": True}
text = json.dumps(order)
print(text)
back = json.loads(text)
print(back["items"][1])''',
task="For <code>items = [(\"Pen\", 1.5, 10), (\"Bag\", 24.99, 2)]</code> print one line per item: name left-aligned in 6, quantity right-aligned in 3, a space, and the line total right-aligned in 8 with 2 decimals. Then print <code>json.dumps({\"b\": 2, \"a\": 1}, sort_keys=True)</code>.",
starter='import json\nitems = [("Pen", 1.5, 10), ("Bag", 24.99, 2)]\n',
hint='for name, price, qty in items: print(f"{name:<6}{qty:>3} {price * qty:>8.2f}")',
solution='import json\nitems = [("Pen", 1.5, 10), ("Bag", 24.99, 2)]\nfor name, price, qty in items:\n    print(f"{name:<6}{qty:>3} {price * qty:>8.2f}")\nprint(json.dumps({"b": 2, "a": 1}, sort_keys=True))')

lesson(id="i7", level="Intermediate", mins=18, title="Classes and objects",
body="""
<p>A <b>class</b> is a blueprint that bundles data (<b>attributes</b>) with behaviour (<b>methods</b>). An <b>object</b> is one thing built from it.</p>
<pre><code>class Course:
    def __init__(self, title, lessons):
        self.title = title        # attribute
        self.lessons = lessons

    def summary(self):            # method
        return f"{self.title}: {self.lessons} lessons"

py = Course("Python", 28)
py.summary()</code></pre>
<ul>
<li><code>__init__</code> runs when you create an object and sets its starting state.</li>
<li><code>self</code> is the object the method is working on.</li>
<li><code>__str__</code> controls what <code>print(obj)</code> shows.</li>
</ul>
""",
example='''class Counter:
    def __init__(self, start=0):
        self.value = start

    def increment(self, step=1):
        self.value += step
        return self

    def __str__(self):
        return f"Counter({self.value})"

c = Counter()
c.increment().increment(5)
print(c)
print(isinstance(c, Counter))''',
task="Write <code>BankAccount(owner, balance=0)</code> with <code>deposit(amount)</code>, <code>withdraw(amount)</code> (raise <code>ValueError(\"Insufficient funds\")</code> if too large) and <code>__str__</code> returning <code>Owner: balance</code>. Create one for <code>\"Leo\"</code>, deposit 100, withdraw 30, print it, then try to withdraw 500 and print the error message.",
starter='class BankAccount:\n    def __init__(self, owner, balance=0):\n        pass\n\n',
hint='In withdraw: if amount > self.balance: raise ValueError("Insufficient funds"). Catch it with except ValueError as e: print(e)',
solution='class BankAccount:\n    def __init__(self, owner, balance=0):\n        self.owner = owner\n        self.balance = balance\n\n    def deposit(self, amount):\n        self.balance += amount\n\n    def withdraw(self, amount):\n        if amount > self.balance:\n            raise ValueError("Insufficient funds")\n        self.balance -= amount\n\n    def __str__(self):\n        return f"{self.owner}: {self.balance}"\n\nacct = BankAccount("Leo")\nacct.deposit(100)\nacct.withdraw(30)\nprint(acct)\ntry:\n    acct.withdraw(500)\nexcept ValueError as e:\n    print(e)')

# =============================== ADVANCED ===============================
lesson(id="a1", level="Advanced", mins=16, title="Inheritance and magic methods",
body="""
<p><b>Inheritance</b> lets a class reuse and extend another. The child class gets every method of the parent and can <b>override</b> some of them. <code>super()</code> calls the parent's version.</p>
<pre><code>class Animal:
    def __init__(self, name): self.name = name
    def speak(self): return "..."

class Dog(Animal):
    def speak(self): return "Woof"</code></pre>
<p><b>Magic (dunder) methods</b> hook your objects into Python's syntax:</p>
<table class="ref"><tr><th>Method</th><th>Enables</th></tr>
<tr><td><code>__repr__</code> / <code>__str__</code></td><td>debug text / <code>print()</code></td></tr>
<tr><td><code>__eq__</code>, <code>__lt__</code></td><td><code>==</code>, <code>&lt;</code> and sorting</td></tr>
<tr><td><code>__len__</code>, <code>__getitem__</code></td><td><code>len(x)</code>, <code>x[i]</code></td></tr>
<tr><td><code>__add__</code></td><td><code>a + b</code></td></tr></table>
""",
example='''class Vector:
    def __init__(self, x, y):
        self.x, self.y = x, y
    def __add__(self, other):
        return Vector(self.x + other.x, self.y + other.y)
    def __eq__(self, other):
        return (self.x, self.y) == (other.x, other.y)
    def __repr__(self):
        return f"Vector({self.x}, {self.y})"

print(Vector(1, 2) + Vector(3, 4))
print(Vector(1, 1) == Vector(1, 1))

class Shape:
    def area(self): return 0
class Square(Shape):
    def __init__(self, side): self.side = side
    def area(self): return self.side ** 2
print([s.area() for s in (Shape(), Square(3))])''',
task="Create <code>Animal(name)</code> with <code>speak()</code> returning <code>\"...\"</code> and <code>__str__</code> returning <code>f\"{name} says {self.speak()}\"</code>. Subclass <code>Dog</code> (<code>Woof</code>) and <code>Cat</code> (<code>Meow</code>). Print <code>Dog(\"Rex\")</code>, <code>Cat(\"Tom\")</code> and <code>Animal(\"Blob\")</code>.",
starter='class Animal:\n    def __init__(self, name):\n        self.name = name\n\n',
hint='Only __str__ lives in Animal. Each subclass overrides speak().',
solution='class Animal:\n    def __init__(self, name):\n        self.name = name\n\n    def speak(self):\n        return "..."\n\n    def __str__(self):\n        return f"{self.name} says {self.speak()}"\n\nclass Dog(Animal):\n    def speak(self):\n        return "Woof"\n\nclass Cat(Animal):\n    def speak(self):\n        return "Meow"\n\nfor pet in (Dog("Rex"), Cat("Tom"), Animal("Blob")):\n    print(pet)')

lesson(id="a2", level="Advanced", mins=15, title="Iterators and generators",
body="""
<p>Anything you can loop over is <b>iterable</b>. <code>iter(x)</code> gives an <b>iterator</b>; <code>next(it)</code> pulls the next value and raises <code>StopIteration</code> at the end.</p>
<p>A <b>generator</b> is a function that uses <code>yield</code>. It produces values one at a time and pauses in between, so it can describe huge or endless sequences using almost no memory.</p>
<pre><code>def count_up(limit):
    n = 1
    while n &lt;= limit:
        yield n
        n += 1</code></pre>
<p>A <b>generator expression</b> looks like a list comprehension with round brackets: <code>sum(x * x for x in range(10**6))</code> never builds the full list.</p>
""",
example='''def countdown(n):
    while n > 0:
        yield n
        n -= 1

gen = countdown(3)
print(next(gen), next(gen), next(gen))
print(list(countdown(5)))

def read_in_chunks(items, size):
    for i in range(0, len(items), size):
        yield items[i:i + size]

for chunk in read_in_chunks(list(range(7)), 3):
    print(chunk)
print(sum(x * x for x in range(1000)))''',
task="Write a generator <code>fibonacci()</code> that yields the Fibonacci numbers forever (0, 1, 1, 2, ...). Print a list of the first 10 using <code>next()</code> or <code>itertools.islice</code>.",
starter='def fibonacci():\n    a, b = 0, 1\n\n',
hint='Loop forever: yield a; a, b = b, a + b. Then list(itertools.islice(fibonacci(), 10))',
solution='import itertools\n\ndef fibonacci():\n    a, b = 0, 1\n    while True:\n        yield a\n        a, b = b, a + b\n\nprint(list(itertools.islice(fibonacci(), 10)))')

lesson(id="a3", level="Advanced", mins=18, title="Decorators",
body="""
<p>Functions are objects: you can store them, pass them and return them. A function defined inside another can remember the outer variables; that's a <b>closure</b>.</p>
<p>A <b>decorator</b> is a function that takes a function and returns a new one that adds behaviour. <code>@name</code> above a <code>def</code> applies it.</p>
<pre><code>import functools

def logged(func):
    @functools.wraps(func)          # keep name and docstring
    def wrapper(*args, **kwargs):
        print("calling", func.__name__)
        return func(*args, **kwargs)
    return wrapper

@logged
def add(a, b): return a + b</code></pre>
<p>Web frameworks use decorators to connect URLs to functions, e.g. <code>@app.get("/users")</code> in FastAPI or <code>@app.route("/")</code> in Flask.</p>
""",
example='''import functools, time

def timer(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        print(f"{func.__name__} took {time.perf_counter() - start:.4f}s")
        return result
    return wrapper

@timer
def slow_sum(n):
    return sum(range(n))

print(slow_sum(100000))

def repeat(times):              # a decorator that takes arguments
    def deco(func):
        def wrapper(*a):
            return [func(*a) for _ in range(times)]
        return wrapper
    return deco

@repeat(3)
def hello(name):
    return f"hi {name}"
print(hello("Asha"))''',
task="Write a decorator <code>shout</code> that upper-cases whatever the function returns, and a decorator <code>count_calls</code> that stores the number of calls in <code>wrapper.calls</code>. Decorate <code>greet(name)</code> (returns <code>f\"hello {name}\"</code>) with both, call it twice with <code>\"asha\"</code> and <code>\"leo\"</code> printing each result, then print <code>greet.calls</code>.",
starter='import functools\n\ndef shout(func):\n    pass\n\ndef count_calls(func):\n    pass\n\n',
hint='Put @count_calls on top, then @shout, so greet.calls belongs to the outer wrapper. In count_calls: wrapper.calls = 0 before returning wrapper; inside: wrapper.calls += 1',
solution='import functools\n\ndef shout(func):\n    @functools.wraps(func)\n    def wrapper(*args, **kwargs):\n        return func(*args, **kwargs).upper()\n    return wrapper\n\ndef count_calls(func):\n    @functools.wraps(func)\n    def wrapper(*args, **kwargs):\n        wrapper.calls += 1\n        return func(*args, **kwargs)\n    wrapper.calls = 0\n    return wrapper\n\n@count_calls\n@shout\ndef greet(name):\n    return f"hello {name}"\n\nprint(greet("asha"))\nprint(greet("leo"))\nprint(greet.calls)')

lesson(id="a4", level="Advanced", mins=12, title="Lambda, map, filter and sorting",
body="""
<p>A <b>lambda</b> is a tiny unnamed function written in one expression: <code>lambda x: x * 2</code>. It is most useful as a <b>key</b> for sorting or as a quick argument.</p>
<pre><code>sorted(words, key=len)                       # shortest first
sorted(people, key=lambda p: p["age"])       # by a dict field
sorted(rows, key=lambda r: (-r[1], r[0]))    # score desc, then name</code></pre>
<p><code>map(f, items)</code> applies <code>f</code> to every item; <code>filter(f, items)</code> keeps items where <code>f</code> is true. Both return lazy iterators; wrap them in <code>list()</code> to see results. Comprehensions often read better, so pick whichever is clearer.</p>
<p><code>functools.reduce</code>, <code>any()</code>, <code>all()</code>, <code>zip()</code> and <code>enumerate()</code> complete the toolkit.</p>
""",
example='''nums = [5, 3, 8, 1]
print(list(map(lambda n: n * 10, nums)))
print(list(filter(lambda n: n > 3, nums)))
words = ["kiwi", "fig", "banana", "apple"]
print(sorted(words, key=len))
print(max(words, key=len))
names, ages = ["Asha", "Leo"], [21, 34]
print(dict(zip(names, ages)))
print(any(n > 7 for n in nums), all(n > 0 for n in nums))''',
task="Sort <code>students = [(\"Mira\", 88), (\"Leo\", 92), (\"Asha\", 88), (\"Ravi\", 75)]</code> by score from high to low, and by name A-Z when scores tie. Print each as <code>Leo 92</code>.",
starter='students = [("Mira", 88), ("Leo", 92), ("Asha", 88), ("Ravi", 75)]\n',
hint='sorted(students, key=lambda s: (-s[1], s[0]))',
solution='students = [("Mira", 88), ("Leo", 92), ("Asha", 88), ("Ravi", 75)]\nfor name, score in sorted(students, key=lambda s: (-s[1], s[0])):\n    print(name, score)')

lesson(id="a5", level="Advanced", mins=15, title="Dataclasses and type hints",
body="""
<p><b>Type hints</b> describe what a value should be. Python doesn't enforce them at runtime, but editors and tools like <code>mypy</code> use them to catch bugs early.</p>
<pre><code>def total(prices: list[float], tax: float = 0.13) -&gt; float: ...
name: str | None = None</code></pre>
<p><code>@dataclass</code> writes the boring parts of a class for you: <code>__init__</code>, <code>__repr__</code> and <code>__eq__</code> are generated from the annotated fields.</p>
<pre><code>from dataclasses import dataclass, field

@dataclass
class Product:
    name: str
    price: float
    qty: int = 0
    tags: list[str] = field(default_factory=list)</code></pre>
<p>Use <code>field(default_factory=list)</code> for mutable defaults, never <code>tags=[]</code>.</p>
""",
example='''from dataclasses import dataclass, field, asdict

@dataclass
class User:
    name: str
    email: str
    roles: list = field(default_factory=list)
    active: bool = True

u = User("Asha", "asha@example.com")
u.roles.append("learner")
print(u)
print(asdict(u))
print(u == User("Asha", "asha@example.com", ["learner"]))''',
task="Make a dataclass <code>Product</code> with <code>name: str</code>, <code>price: float</code>, <code>qty: int = 0</code> and a method <code>value()</code> returning <code>price * qty</code>. Build a list with <code>Product(\"Pen\", 1.5, 10)</code>, <code>Product(\"Bag\", 25.0, 2)</code>, <code>Product(\"Ink\", 4.0)</code>. Print the first product, then <code>Inventory value: 65.0</code> using the real sum.",
starter='from dataclasses import dataclass\n\n',
hint='sum(p.value() for p in products)',
solution='from dataclasses import dataclass\n\n@dataclass\nclass Product:\n    name: str\n    price: float\n    qty: int = 0\n\n    def value(self) -> float:\n        return self.price * self.qty\n\nproducts = [Product("Pen", 1.5, 10), Product("Bag", 25.0, 2), Product("Ink", 4.0)]\nprint(products[0])\nprint(f"Inventory value: {sum(p.value() for p in products)}")')

lesson(id="a6", level="Advanced", mins=16, title="collections, itertools and regex",
body="""
<p>The standard library has power tools for data work:</p>
<table class="ref"><tr><th>Tool</th><th>What it does</th></tr>
<tr><td><code>Counter</code></td><td>counts things; <code>.most_common(n)</code></td></tr>
<tr><td><code>defaultdict(list)</code></td><td>dict that creates missing keys for you</td></tr>
<tr><td><code>deque</code></td><td>fast queue: append and pop at both ends</td></tr>
<tr><td><code>itertools.groupby</code>, <code>chain</code>, <code>combinations</code></td><td>grouping, joining and combining iterables</td></tr></table>
<p><b>Regular expressions</b> (<code>re</code>) find patterns in text. <code>\\d</code> digit, <code>\\w</code> word character, <code>+</code> one or more, <code>[...]</code> a set of characters. Write patterns as raw strings: <code>r"\\d+"</code>.</p>
<pre><code>re.findall(r"\\d+", "a1b22c333")   # ['1', '22', '333']
re.sub(r"\\s+", " ", text)         # squeeze spaces</code></pre>
""",
example='''from collections import Counter, defaultdict
import itertools, re

votes = ["py", "js", "py", "go", "py", "js"]
print(Counter(votes).most_common(2))

by_letter = defaultdict(list)
for w in ["apple", "avocado", "banana", "blueberry", "cherry"]:
    by_letter[w[0]].append(w)
print(dict(by_letter))

print(list(itertools.combinations("ABC", 2)))
print(re.findall(r"\\d+", "Order 66 shipped in 3 boxes"))''',
task="In <code>text = \"the cat and the hat and the bat\"</code>, print the 2 most common words with <code>Counter</code>. Then use <code>re.findall</code> to print every email address in <code>\"mail asha@pyforge.dev or leo@example.com today\"</code>.",
starter='from collections import Counter\nimport re\n\ntext = "the cat and the hat and the bat"\n',
hint=r'Counter(text.split()).most_common(2) and the pattern r"[\w.]+@[\w.]+\w"',
solution='from collections import Counter\nimport re\n\ntext = "the cat and the hat and the bat"\nprint(Counter(text.split()).most_common(2))\nprint(re.findall(r"[\\w.]+@[\\w.]+\\w", "mail asha@pyforge.dev or leo@example.com today"))')

# ================================= PRO ==================================
lesson(id="p1", level="Pro", mins=15, title="Context managers and files",
body="""
<p>A <b>context manager</b> sets something up and guarantees it is cleaned up, even if an error happens. The <code>with</code> statement uses one.</p>
<pre><code>with open("notes.txt", "w", encoding="utf-8") as f:
    f.write("hello\\n")
# the file is closed here, even after an exception</code></pre>
<p>File modes: <code>"r"</code> read, <code>"w"</code> write (replaces), <code>"a"</code> append. Prefer <code>pathlib.Path</code> for paths: <code>Path("data") / "users.json"</code>.</p>
<p>Build your own with a class (<code>__enter__</code> / <code>__exit__</code>) or, more simply, with <code>@contextlib.contextmanager</code> and a single <code>yield</code>.</p>
<div class="note"><b>Browser mode:</b> the in-browser runner can't touch your disk, so the example uses <code>io.StringIO</code>, an in-memory file. On localhost, real files work.</div>
""",
example='''import io
from contextlib import contextmanager

buffer = io.StringIO()          # behaves like an open text file
with buffer as f:
    f.write("line 1\\n")
    f.write("line 2\\n")
    print(f.getvalue().splitlines())

@contextmanager
def tag(name):
    print(f"<{name}>")
    try:
        yield
    finally:
        print(f"</{name}>")

with tag("div"):
    print("  content")''',
task="Write a context manager <code>step(name)</code> with <code>@contextmanager</code> that prints <code>start NAME</code> on entry and <code>end NAME</code> on exit, even when an error occurs. Use it for <code>\"load\"</code> printing <code>working</code> inside, then for <code>\"save\"</code> where the body raises <code>ValueError(\"disk full\")</code>; catch it outside and print <code>caught: disk full</code>.",
starter='from contextlib import contextmanager\n\n',
hint='Put yield inside try and the end print inside finally.',
solution='from contextlib import contextmanager\n\n@contextmanager\ndef step(name):\n    print(f"start {name}")\n    try:\n        yield\n    finally:\n        print(f"end {name}")\n\nwith step("load"):\n    print("working")\n\ntry:\n    with step("save"):\n        raise ValueError("disk full")\nexcept ValueError as e:\n    print(f"caught: {e}")')

lesson(id="p2", level="Pro", mins=14, title="Testing your code",
body="""
<p>Tests are small programs that check your code gives the right answers. They let you change code without fear.</p>
<p>The simplest test is an <code>assert</code>: <code>assert add(2, 2) == 4</code> does nothing when true and raises <code>AssertionError</code> when false.</p>
<p>Real projects use <b>pytest</b>. Put tests in files named <code>test_*.py</code>, write functions named <code>test_*</code>, and run <code>pytest</code> in a terminal:</p>
<pre><code># test_text.py
from text import slugify

def test_slugify_spaces():
    assert slugify("Hello World") == "hello-world"

def test_slugify_empty():
    assert slugify("") == ""</code></pre>
<ul><li>Test normal cases, edge cases (empty, zero, huge) and error cases.</li><li>One behaviour per test, with a name that says what it checks.</li></ul>
""",
example='''def slugify(text):
    words = "".join(c.lower() if c.isalnum() else " " for c in text).split()
    return "-".join(words)

tests = [
    ("Hello World", "hello-world"),
    ("  Python 3.12!  ", "python-3-12"),
    ("", ""),
]
for given, want in tests:
    got = slugify(given)
    status = "PASS" if got == want else "FAIL"
    print(f"{status}: slugify({given!r}) -> {got!r}")''',
task="Write <code>is_palindrome(text)</code> that ignores case, spaces and punctuation. Use <code>assert</code> to check that <code>\"Racecar\"</code>, <code>\"A man, a plan, a canal: Panama\"</code> and <code>\"\"</code> are palindromes and <code>\"python\"</code> is not. If every assert passes, print <code>All tests passed</code>.",
starter='def is_palindrome(text):\n    pass\n\n',
hint='Keep only c.lower() for c in text if c.isalnum(), then compare the string to its reverse [::-1].',
solution='def is_palindrome(text):\n    cleaned = "".join(c.lower() for c in text if c.isalnum())\n    return cleaned == cleaned[::-1]\n\nassert is_palindrome("Racecar")\nassert is_palindrome("A man, a plan, a canal: Panama")\nassert is_palindrome("")\nassert not is_palindrome("python")\nprint("All tests passed")')

lesson(id="p3", level="Pro", mins=18, title="Algorithms and Big-O",
body="""
<p><b>Big-O</b> describes how the work grows as the input grows. It's how you predict whether code will still be fast with a million rows.</p>
<table class="ref"><tr><th>Big-O</th><th>Name</th><th>Example</th></tr>
<tr><td>O(1)</td><td>constant</td><td>dict lookup, list index</td></tr>
<tr><td>O(log n)</td><td>logarithmic</td><td>binary search</td></tr>
<tr><td>O(n)</td><td>linear</td><td>one loop, <code>x in list</code></td></tr>
<tr><td>O(n log n)</td><td>linearithmic</td><td><code>sorted()</code></td></tr>
<tr><td>O(n²)</td><td>quadratic</td><td>a loop inside a loop</td></tr></table>
<p><b>Binary search</b> finds an item in a <em>sorted</em> list by checking the middle and throwing away half each step: 1,000,000 items need at most 20 checks.</p>
<div class="note"><b>Practical wins:</b> use a <code>set</code> or <code>dict</code> for membership tests instead of a list, and let <code>sorted()</code> do sorting.</div>
""",
example='''import time

data = list(range(200000))
as_set = set(data)
t = time.perf_counter(); 199999 in data;   a = time.perf_counter() - t
t = time.perf_counter(); 199999 in as_set; b = time.perf_counter() - t
print(f"list: {a:.6f}s   set: {b:.6f}s")

def two_sum(nums, target):          # O(n) with a dict
    seen = {}
    for i, n in enumerate(nums):
        if target - n in seen:
            return seen[target - n], i
        seen[n] = i

print(two_sum([2, 7, 11, 15], 9))''',
task="Write <code>binary_search(items, target)</code> for a sorted list that returns the index of <code>target</code>, or <code>-1</code> if missing. With <code>nums = [3, 8, 15, 23, 42, 57, 91]</code> print the result for 42, 3, 91 and 50.",
starter='def binary_search(items, target):\n    low, high = 0, len(items) - 1\n\n',
hint='while low <= high: mid = (low + high) // 2; compare items[mid] with target and move low or high.',
solution='def binary_search(items, target):\n    low, high = 0, len(items) - 1\n    while low <= high:\n        mid = (low + high) // 2\n        if items[mid] == target:\n            return mid\n        if items[mid] < target:\n            low = mid + 1\n        else:\n            high = mid - 1\n    return -1\n\nnums = [3, 8, 15, 23, 42, 57, 91]\nfor t in (42, 3, 91, 50):\n    print(binary_search(nums, t))')

lesson(id="p4", level="Pro", mins=18, title="Calling a REST API", api=True,
body="""
<p>An <b>API</b> (Application Programming Interface) lets programs talk to each other. Web APIs use <b>HTTP</b>: you send a <b>request</b> to a URL and get back a <b>response</b> with a status code and usually JSON.</p>
<table class="ref"><tr><th>Method</th><th>Meaning</th><th>Example</th></tr>
<tr><td>GET</td><td>read data</td><td><code>GET /api/applications</code></td></tr>
<tr><td>POST</td><td>create / submit</td><td><code>POST /api/decisions</code></td></tr>
<tr><td>PUT / PATCH</td><td>replace / update</td><td><code>PATCH /api/users/7</code></td></tr>
<tr><td>DELETE</td><td>remove</td><td><code>DELETE /api/users/7</code></td></tr></table>
<p>Status codes: <b>200</b> OK, <b>201</b> created, <b>400</b> bad request, <b>401</b> not logged in, <b>404</b> not found, <b>500</b> server error.</p>
<p>In PyForge every program has an <code>api</code> object connected to the <b>Approval API</b>: <code>api.get("/applications")</code> and <code>api.post("/decisions", {...})</code> return Python dicts. On your own machine the same idea uses the <code>requests</code> package:</p>
<pre><code>import requests
r = requests.get("http://localhost:8000/api/applications", timeout=5)
r.raise_for_status()
data = r.json()</code></pre>
""",
example='''health = api.get("/health")
print("API status:", health["status"])

data = api.get("/applications")
print("Applications:", data["count"])
first = data["items"][0]
print(first["name"], "| score", first["score"], "| attendance", first["attendance"])

one = api.get("/applications/104")
print(one["name"], "from", one["country"])
print(api.get("/applications/999"))     # a 404 comes back as an error dict''',
task="Call <code>GET /applications</code>. Print <code>Total: N</code>, then the name of every applicant with a score of 80 or more, one per line, in the order the API returns them.",
starter='data = api.get("/applications")\n',
hint='for app in data["items"]: if app["score"] >= 80: print(app["name"])',
solution='data = api.get("/applications")\nprint(f"Total: {data[\'count\']}")\nfor app in data["items"]:\n    if app["score"] >= 80:\n        print(app["name"])')

lesson(id="p5", level="Pro", mins=20, title="Build your own API",
body="""
<p>An API server receives a request (method + path + body), runs a <b>handler</b> function, and returns a status code plus JSON. Frameworks do the plumbing; the core idea is a <b>router</b> that maps routes to handlers.</p>
<p>With <b>FastAPI</b> (run <code>pip install fastapi uvicorn</code> on your machine):</p>
<pre><code>from fastapi import FastAPI, HTTPException
app = FastAPI()
TODOS = {1: "learn python"}

@app.get("/todos/{todo_id}")
def read_todo(todo_id: int):
    if todo_id not in TODOS:
        raise HTTPException(404, "not found")
    return {"id": todo_id, "text": TODOS[todo_id]}

# run:  uvicorn main:app --reload   then open http://127.0.0.1:8000/docs</code></pre>
<p>The PyForge local server (<code>server.py</code>) is built the same way with only the standard library: its <code>api()</code> function is the router behind every endpoint you call in the API Lab. Read it once you finish this lesson.</p>
<p>In this exercise you build the router yourself, without a network, so you can see every moving part.</p>
""",
example='''ROUTES = {}

def route(method, path):                 # a decorator, like @app.get
    def register(func):
        ROUTES[(method, path)] = func
        return func
    return register

@route("GET", "/hello")
def hello(body):
    return 200, {"message": "hi"}

def handle(method, path, body=None):
    handler = ROUTES.get((method, path))
    if handler is None:
        return 404, {"error": "not found"}
    return handler(body)

print(handle("GET", "/hello"))
print(handle("GET", "/nope"))''',
task="Build a tiny to-do API. Keep <code>TODOS = {}</code>. Write <code>handle(method, path, body=None)</code>: <code>POST /todos</code> with <code>{\"text\": ...}</code> stores it under the next id (1, 2, ...) and returns <code>(201, {\"id\": id, \"text\": text})</code>; <code>GET /todos</code> returns <code>(200, list of those dicts)</code>; anything else returns <code>(404, {\"error\": \"not found\"})</code>. Print the results of: POST \"learn python\", POST \"build api\", GET /todos, DELETE /todos.",
starter='TODOS = {}\n\ndef handle(method, path, body=None):\n    pass\n\n',
hint='new_id = len(TODOS) + 1. For GET return [{"id": i, "text": t} for i, t in TODOS.items()].',
solution='TODOS = {}\n\ndef handle(method, path, body=None):\n    if (method, path) == ("POST", "/todos"):\n        new_id = len(TODOS) + 1\n        TODOS[new_id] = body["text"]\n        return 201, {"id": new_id, "text": body["text"]}\n    if (method, path) == ("GET", "/todos"):\n        return 200, [{"id": i, "text": t} for i, t in TODOS.items()]\n    return 404, {"error": "not found"}\n\nprint(handle("POST", "/todos", {"text": "learn python"}))\nprint(handle("POST", "/todos", {"text": "build api"}))\nprint(handle("GET", "/todos"))\nprint(handle("DELETE", "/todos"))')

lesson(id="p6", level="Pro", mins=25, title="Capstone: the Approval API", api=True,
body="""
<p>Time to put it all together. The Approval API holds 8 scholarship applications. Your program must review each one, send a decision to the API, and get a perfect report.</p>
<p><b>Approval rules</b> (also available from <code>GET /rules</code>): approve when <b>age ≥ 16</b> and <b>score ≥ 70</b> and <b>attendance ≥ 80</b>; otherwise reject.</p>
<table class="ref"><tr><th>Endpoint</th><th>Does</th></tr>
<tr><td><code>POST /reset</code></td><td>clears all decisions (start clean)</td></tr>
<tr><td><code>GET /rules</code></td><td>the thresholds as a dict</td></tr>
<tr><td><code>GET /applications</code></td><td>all applications</td></tr>
<tr><td><code>POST /decisions</code></td><td>body <code>{"id": 101, "decision": "approved", "reason": "..."}</code></td></tr>
<tr><td><code>GET /report</code></td><td>approved, rejected, pending, correct, accuracy</td></tr></table>
<p>Good API clients read the rules from the API instead of hard-coding them, give a reason for each decision, and check the report at the end.</p>
""",
example='''print(api.get("/rules"))
print(api.post("/decisions", {"id": 101, "decision": "approved", "reason": "meets all rules"}))
print(api.post("/decisions", {"id": 999, "decision": "approved"}))   # 404 error
print(api.get("/report"))
api.post("/reset")''',
task="Reset the API, read the rules, decide every application and POST each decision with a reason. Finally print <code>Approved: X</code>, <code>Rejected: Y</code> and <code>Accuracy: Z%</code> from <code>GET /report</code>. Aim for 100%.",
starter='api.post("/reset")\nrules = api.get("/rules")\n',
hint='For each app build ok = app["age"] >= rules["min_age"] and ...; decision = "approved" if ok else "rejected".',
solution='api.post("/reset")\nrules = api.get("/rules")\n\ndef review(app):\n    ok = (app["age"] >= rules["min_age"]\n          and app["score"] >= rules["min_score"]\n          and app["attendance"] >= rules["min_attendance"])\n    return ("approved", "meets all rules") if ok else ("rejected", "below a threshold")\n\nfor app in api.get("/applications")["items"]:\n    decision, reason = review(app)\n    api.post("/decisions", {"id": app["id"], "decision": decision, "reason": reason})\n\nreport = api.get("/report")\nprint(f"Approved: {report[\'approved\']}")\nprint(f"Rejected: {report[\'rejected\']}")\nprint(f"Accuracy: {report[\'accuracy\']}%")')
