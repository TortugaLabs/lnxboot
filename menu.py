import curses
import time
import sys

def main(stdscr, options, default_tag, timeout, title):
    curses.curs_set(0)  # Hide cursor
    stdscr.timeout(1000)  # Refresh every second

    max_display_width = curses.COLS - 4
    max_display_height = curses.LINES - 6  # Allow space for the countdown timer

    # Find default index
    current_index = next((i for i, option in enumerate(options) if option[0] == default_tag), 0)
    if current_index >= len(options):
        current_index = 0

    first_display_index = 0  # Start index of the displayed options
    remaining_time = timeout

    while True:
        stdscr.clear()
        height, width = stdscr.getmaxyx()

        # Calculate the dimensions and position of the menu
        menu_height = min(len(options), max_display_height)
        menu_width = min(max(len(desc) for _, desc in options) + 4, max_display_width)
        start_y = height // 2 - menu_height // 2
        start_x = width // 2 - menu_width // 2

        # Draw the title
        title_x = width // 2 - len(title) // 2
        stdscr.addstr(start_y - 2, title_x, title, curses.A_BOLD)

        # Draw the border
        for i in range(start_y, start_y + menu_height + 2):
            stdscr.addch(i, start_x, curses.ACS_VLINE)
            stdscr.addch(i, start_x + menu_width - 1, curses.ACS_VLINE)

        for i in range(start_x, start_x + menu_width):
            stdscr.addch(start_y, i, curses.ACS_HLINE)
            stdscr.addch(start_y + menu_height + 1, i, curses.ACS_HLINE)

        stdscr.addch(start_y, start_x, curses.ACS_ULCORNER)
        stdscr.addch(start_y, start_x + menu_width - 1, curses.ACS_URCORNER)
        stdscr.addch(start_y + menu_height + 1, start_x, curses.ACS_LLCORNER)
        stdscr.addch(start_y + menu_height + 1, start_x + menu_width - 1, curses.ACS_LRCORNER)

        # Display menu options within the bordered area
        for i, (tag, desc) in enumerate(options[first_display_index:first_display_index + menu_height]):
            x = start_x + 2
            y = start_y + 1 + i
            display_desc = desc[:menu_width - 4]
            if i + first_display_index == current_index:
                stdscr.attron(curses.A_REVERSE)
            stdscr.addstr(y, x, display_desc)
            if i + first_display_index == current_index:
                stdscr.attroff(curses.A_REVERSE)

        if not remaining_time is None:
          # Draw the countdown timer
          timeout_msg = f"Automatic boot in {remaining_time} second"
          if remaining_time != 1: timeout_msg += 's'
          timer_y = start_y + menu_height + 2
          timer_x = (width - len(timeout_msg)) // 2
          stdscr.addstr(timer_y, timer_x, timeout_msg )

        stdscr.refresh()

        start_time = time.time()
        key = stdscr.getch()
        elapsed_time = time.time() - start_time

        if key == curses.ERR:
          if not remaining_time is None:
            remaining_time -= int(elapsed_time)
            if remaining_time <= 0:
                break
        else:
            remaining_time = None  # Reset the timeout if there's user interaction

        # Handle key press
        if key == curses.KEY_UP:
            if current_index > 0:
                current_index -= 1
                if current_index < first_display_index:
                    first_display_index -= 1
        elif key == curses.KEY_DOWN:
            if current_index < len(options) - 1:
                current_index += 1
                if current_index >= first_display_index + menu_height:
                    first_display_index += 1
        elif key == ord('\n'):
            break

    selected_tag = options[current_index][0]

    # Write selected tag to output file
    return selected_tag

if __name__ == '__main__':
    options = [('tag1', 'Description 1'), ('tag2', 'Description 2'), ('tag3', 'Description 3'), ('tag4', 'Description 4'), ('tag5', 'Description 5'), ('tag6', 'Description 6')]
    default_tag = 'tag1'
    timeout = 10
    title = 'Boot menu'

    res = curses.wrapper(main, options, default_tag, timeout, title)
    print(res)

