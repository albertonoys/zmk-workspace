import unittest
import os
import sys
import difflib

# Add the directory containing format_keymap.py to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import format_keymap

# ANSI color codes
RED = '\033[91m'
GREEN = '\033[92m'
BLUE = '\033[94m'
ENDC = '\033[0m'

class TestFormatKeymap(unittest.TestCase):

    def setUp(self):
        self.test_dir = os.path.dirname(os.path.abspath(__file__))
        self.project_root = os.path.dirname(self.test_dir)
        self.input_file = os.path.join(self.project_root, 'config', 'splitkb_aurora_sweep.keymap')
        self.expected_output_file = os.path.join(self.test_dir, 'splitkb_aurora_sweep_formatted.keymap')

    def highlight_whitespace(self, line):
        return line.replace(' ', '·').replace('\t', '→→→→')

    def color_diff(self, diff_line):
        if diff_line.startswith('+'):
            return f"{GREEN}{self.highlight_whitespace(diff_line)}{ENDC}"
        elif diff_line.startswith('-'):
            return f"{RED}{self.highlight_whitespace(diff_line)}{ENDC}"
        elif diff_line.startswith('^'):
            return f"{BLUE}{diff_line}{ENDC}"
        else:
            return self.highlight_whitespace(diff_line)

    def test_format_keymap_output(self):
        from io import StringIO
        import sys

        captured_output = StringIO()
        sys.stdout = captured_output

        format_keymap.main(self.input_file)

        sys.stdout = sys.__stdout__

        actual_output = captured_output.getvalue()

        with open(self.expected_output_file, 'r') as f:
            expected_output = f.read()

        if actual_output != expected_output:
            diff = list(difflib.unified_diff(
                expected_output.splitlines(keepends=True),
                actual_output.splitlines(keepends=True),
                fromfile='expected',
                tofile='actual',
                n=3  # context lines
            ))

            formatted_diff = '\n'.join(self.color_diff(line.rstrip('\n')) for line in diff)

            error_message = (
                "Formatted output doesn't match expected output.\n"
                "Diff (· represents space, → represents tab):\n\n"
                f"{formatted_diff}\n\n"
                "Note:\n"
                f"{RED}- Lines in red{ENDC} are in the expected output but not in the actual output.\n"
                f"{GREEN}+ Lines in green{ENDC} are in the actual output but not in the expected output.\n"
                f"{BLUE}^ Blue carets{ENDC} indicate the specific differences within the line.\n"
                "Check for trailing spaces or inconsistent whitespace."
            )

            self.fail(error_message)

if __name__ == '__main__':
    unittest.main()
