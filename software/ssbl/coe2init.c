#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINES 512  // Maximum number of lines to handle

int main() {
    FILE *file;
    char filename[100]="ssbl.coe";
    char line[100];
    char formatted_output[MAX_LINES][24];  // Store formatted VHDL output
    int line_count = 0;

    // Prompt user to enter the .coe filename
    // printf("Enter the .coe filename: ");
    // scanf("%s", filename);

    // Open the .coe file
    file = fopen(filename, "r");
    if (file == NULL) {
        printf("Could not open file %s\n", filename);
        return 1;
    }

    // Skip initial lines until memory vector starts
    while (fgets(line, sizeof(line), file)) {
        if (strstr(line, "memory_initialization_vector=") != NULL) {
            break;
        }
    }

    // Read the values into the formatted output
    while (fgets(line, 10, file) && line_count < MAX_LINES) {
        // Strip newline characters and commas
        line[strcspn(line, "\r\n")] = 0;  // Remove newlines
        if (line[0] == ';') break;        // Stop at the end of the vector
        line[9] = '\0';
        // printf("%s\r\n", line);
        // Store the formatted value as VHDL x"........"
        sprintf(formatted_output[line_count], " %3d => x\"%8s\"", line_count, line);
        line_count++;
    }

    fclose(file);

    // Print the formatted output as a VHDL ROM constant
    printf("constant rom_memory : rom_type := (\n");
    for (int i = 0; i < line_count; i++) {
        if (i%4 == 0) printf("   ");
        printf("%s", formatted_output[i]);
        if (i < line_count - 1) {
            printf(",");  // Add a comma and newline except for the last element
            if (i%4 == 3)
                printf("\n");
        }
    }
    printf("\n);\n");

    return 0;
}
