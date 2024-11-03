from gedcom.element.individual import IndividualElement
from gedcom.parser import Parser
import re
from datetime import datetime

def parse_date(date_str):
    """Parse a date string into a datetime object."""
    try:
        return datetime.strptime(date_str, "%d %b %Y")
    except ValueError:
        try:
            return datetime.strptime(date_str, "%b %Y")
        except ValueError:
            try:
                return datetime.strptime(date_str, "%Y")
            except ValueError:
                return None

def find_duplicates(individuals):
    """Find duplicates based on name and birth date."""
    duplicates = {}
    for indi in individuals:
        key = (indi.name, parse_date(indi.get_birth_data()[0]) if indi.birth else None)
        if key in duplicates:
            duplicates[key].append(indi)
        else:
            duplicates[key] = [indi]
    return [group for group in duplicates.values() if len(group) > 1]

def merge_individuals(duplicates):
    """Merge duplicate individuals."""
    merged = []
    for group in duplicates:
        primary = group[0]
        for duplicate in group[1:]:
            # Merge notes, sources, etc. Here's a basic merge:
            primary_notes = primary.get_notes() + duplicate.get_notes()
            primary.set_note(primary_notes[0] if primary_notes else None)
            # You'd expand this for other data like events, sources, etc.
        merged.append(primary)
    return merged

def clean_individual_data(individual):
    """Clean individual data, standardize formats."""
    # Standardize name format
    if individual.name:
        name_parts = individual.name.split('/')
        individual.set_name(f"{name_parts[0].strip()} /{name_parts[1].strip()}/")
    
    # Standardize dates
    if individual.birth:
        birth_date = individual.get_birth_data()[0]
        if birth_date:
            cleaned_date = parse_date(birth_date)
            if cleaned_date:
                individual.set_birth_data(cleaned_date.strftime("%d %b %Y"))
            else:
                print(f"Unrecognized birth date format for {individual.name}: {birth_date}")
    
    # Similar logic for death or other events

def clean_gedcom(file_path):
    gedcom_parser = Parser()
    gedcom_parser.parse_file(file_path)
    root = gedcom_parser.get_root_element()

    # Clean individual data
    for individual in root.get_individuals():
        clean_individual_data(individual)

    # Find and merge duplicates
    duplicates = find_duplicates(root.get_individuals())
    if duplicates:
        print(f"Found {sum(len(d) - 1 for d in duplicates)} duplicates.")
        merged_individuals = merge_individuals(duplicates)
        # Remove duplicates from the root
        for group in duplicates:
            for duplicate in group[1:]:
                root.remove_child_element(duplicate)

    # Save cleaned GEDCOM
    with open('cleaned.ged', 'w') as cleaned_file:
        cleaned_file.write(str(root))

# Example usage
clean_gedcom('your_gedcom_file.ged')