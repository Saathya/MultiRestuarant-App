import 'package:flutter/material.dart';
import 'package:multi_restaurant_app/model/nearby_restaurant_model.dart';

class FoodItemCell extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap; // Define onTap as a callback function
  const FoodItemCell(
      {super.key, required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Helper function to parse TimeOfDay from string
    TimeOfDay parseTimeOfDay(String timeString) {
      List<String> parts = timeString.split(' ');
      List<int> timeParts = parts[0].split(':').map(int.parse).toList();
      int hour = timeParts[0];
      int minute = int.parse(timeParts[1].toString());
      if (parts[1].toLowerCase() == 'pm' && hour < 12) {
        hour += 12;
      }
      return TimeOfDay(hour: hour, minute: minute);
    }

    bool isTimeOfDayAM(TimeOfDay time) {
      return time.hour < 12;
    }

    // Helper function to adjust TimeOfDay to PM if needed
    TimeOfDay adjustTimeOfDayPM(TimeOfDay time) {
      return TimeOfDay(hour: time.hour + 12, minute: time.minute);
    }

    // Function to determine if the restaurant is currently open
    bool isOpenNow() {
      // Get current time
      DateTime now = DateTime.now();
      // Parse restaurant timings
      List<String> timings = restaurant.timing.split(' to ');
      // Parse open and close times
      TimeOfDay openTime = parseTimeOfDay(timings[0]);
      TimeOfDay closeTime = parseTimeOfDay(timings[1]);

      // Convert current time to TimeOfDay format
      TimeOfDay currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

      // Compare current time with open and close times
      if (isTimeOfDayAM(openTime) && !isTimeOfDayAM(closeTime)) {
        closeTime = adjustTimeOfDayPM(closeTime);
      } else if (!isTimeOfDayAM(openTime) && isTimeOfDayAM(closeTime)) {
        openTime = adjustTimeOfDayPM(openTime);
      }

      if (currentTime.hour > openTime.hour ||
          (currentTime.hour == openTime.hour &&
              currentTime.minute >= openTime.minute)) {
        if (currentTime.hour < closeTime.hour ||
            (currentTime.hour == closeTime.hour &&
                currentTime.minute <= closeTime.minute)) {
          return true; // Restaurant is open
        }
      }
      return false; // Restaurant is closed
    }

    // Function to format the timing string based on current open status
    Widget formatTiming() {
      String status = isOpenNow() ? 'Open' : 'Closed';
      Color statusColor = isOpenNow() ? Colors.green : Colors.red;

      return Text(
        status,
        style: TextStyle(
          fontSize: 14,
          color: statusColor,
          fontWeight: FontWeight.bold,
        ),
      );
    }


    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              restaurant.imageUrl,
              width: 150,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),

          // Details Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ratings Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${restaurant.ratings} '),
                      ],
                    ),
                    Text(
                      restaurant.availability == true
                          ? 'Table Available'
                          : 'Not Available',
                      style: TextStyle(
                        fontSize: 14,
                        color: restaurant.availability == true
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Name Section
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),

                // Address with City Name Section
                Text(
                  '${restaurant.address}, ${restaurant.cityName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                // Timing Section
                formatTiming(),
                const SizedBox(height: 10),

                // Book Now Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
