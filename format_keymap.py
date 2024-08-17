import re
import sys

CELL_WIDTH = 21

def extract_layers(file_content):
    layer_pattern = r'(\w+_layer)\s*{([^}]*)}'
    layers = re.findall(layer_pattern, file_content, re.DOTALL)
    return layers

def format_cell(value):
    trimmed_value = value.rstrip()
    if not trimmed_value:
        return ' ' * CELL_WIDTH
    value_length = len(trimmed_value)
    padding = max(CELL_WIDTH - value_length - 1, 0)
    return f"{trimmed_value}{' ' * padding}"

def format_keymap(layer_content):
    bindings_match = re.search(r'bindings\s*=\s*<([^>]*)>', layer_content, re.DOTALL)
    if not bindings_match:
        return layer_content  # Return original content if no bindings found

    bindings = bindings_match.group(1)
    rows = re.findall(r'&[\w\s]+', bindings)

    num_columns = 10
    grid = [rows[i:i+num_columns] + [''] * (num_columns - len(rows[i:i+num_columns]))
            for i in range(0, len(rows), num_columns)]

    while len(grid) < 4:
        grid.append([''] * num_columns)

    output = []
    output.append(f"bindings = <")
    output.append(f"//╭{'─'*(CELL_WIDTH-2)}┬{'─'*(CELL_WIDTH-2)}┬{'─'*(CELL_WIDTH-2)}┬{'─'*(CELL_WIDTH-2)}┬{'─'*(CELL_WIDTH-2)}╮ ╭{'─'*(CELL_WIDTH-2)}┬{'─'*(CELL_WIDTH-2)}┬{'─'*(CELL_WIDTH-2)}┬{'─'*(CELL_WIDTH-2)}┬{'─'*(CELL_WIDTH-2)}╮")

    for i in range(3):
        row_output = "    "
        for j in range(5):
            row_output += format_cell(grid[i][j])
        row_output += "  "
        for j in range(5, 10):
            row_output += format_cell(grid[i][j])
        output.append(row_output.rstrip())  # Remove trailing whitespace
        if i < 2:
            output.append(f"//├{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┤ ├{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┤")

    output.append(f"//╰{'─'*(CELL_WIDTH-2)}┴{'─'*(CELL_WIDTH-2)}┴{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┤ ├{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┼{'─'*(CELL_WIDTH-2)}┴{'─'*(CELL_WIDTH-2)}┴{'─'*(CELL_WIDTH-2)}╯")
    thumb_row = ' ' * (CELL_WIDTH * 3 + 1)
    thumb_row += format_cell(grid[3][0])
    thumb_row += format_cell(grid[3][1])
    thumb_row += "  "
    thumb_row += format_cell(grid[3][2])
    thumb_row += format_cell(grid[3][3])
    output.append(thumb_row.rstrip())  # Remove trailing whitespace
    output.append(f"//{(' '*(CELL_WIDTH*3-3))}╰{'─'*(CELL_WIDTH-2)}┴{'─'*(CELL_WIDTH-2)}╯ ╰{'─'*(CELL_WIDTH-2)}┴{'─'*(CELL_WIDTH-2)}╯")
    output.append("            >;")

    formatted_bindings = "\n".join(output)
    return re.sub(r'bindings\s*=\s*<[^>]*>', formatted_bindings, layer_content, flags=re.DOTALL)

def main(file_path):
    try:
        with open(file_path, 'r') as file:
            content = file.read()

        layers = extract_layers(content)
        for layer_name, layer_content in layers:
            formatted_layer = format_keymap(layer_content)
            content = content.replace(f"{layer_name} {{{layer_content}}}", f"{layer_name} {{{formatted_layer}}}")

        print(content.rstrip())  # Print the formatted content to console, removing trailing newline

    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")
        raise

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script_name.py path/to/your/keymap.keymap")
    else:
        main(sys.argv[1])
