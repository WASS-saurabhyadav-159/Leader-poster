import 'package:flutter/material.dart';
import '../../../config/colors.dart';

class EventSelector extends StatefulWidget {
  final List<String> events;
  final EventSelectorController? controller;
  final Function(String)? onSelected;

  const EventSelector(this.events, {super.key, this.controller, this.onSelected});

  @override
  State<EventSelector> createState() => _EventSelectorState();
}

class _EventSelectorState extends State<EventSelector> {
  late List<String> events;
  late EventSelectorController controller;

  @override
  void initState() {
    super.initState();
    events = widget.events;
    controller = widget.controller ?? EventSelectorController();

    // ✅ Notify parent initially if a default event exists
    if (events.isNotEmpty) {
      widget.onSelected?.call(events[controller.selectedEvent]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        itemCount: events.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, ind) {
          return GestureDetector(
            onTap: () {
              setState(() {
                controller.setSelectedEvent(ind);
              });
              widget.onSelected?.call(events[ind]); // ✅ Notify parent
            },
            child: EventDisplay(
              events[ind],
              selected: ind == controller.selectedEvent,
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
      ),
    );
  }
}

class EventSelectorController {
  int selectedEvent;
  final int initialSelection;
  final void Function(int event)? onSelectionChange;

  EventSelectorController({this.initialSelection = 0, this.onSelectionChange})
      : selectedEvent = initialSelection;

  void setSelectedEvent(int event) {
    selectedEvent = event;
    onSelectionChange?.call(event);
  }
}

class EventDisplay extends StatelessWidget {
  final String eventName;
  final bool selected;

  const EventDisplay(this.eventName, {super.key, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? SharedColors.selectedEventColor : SharedColors.unselectedEventColor,
        border: Border.all(color: SharedColors.categoryHighlightBorderColor, width: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        eventName,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: selected ? Colors.black : Colors.black, // ✅ Improved visibility
        ),
      ),
    );
  }
}
