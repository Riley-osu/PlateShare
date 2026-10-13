import 'package:flutter/material.dart';
import 'main.dart';

class FoodListPage extends StatefulWidget {
  final List<FoodPost> posts;
  const FoodListPage({super.key, required this.posts});

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "No food posts available yet.\nOrganizations can create posts in the Post tab.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.posts.length,
      itemBuilder: (context, index) {
        var post = widget.posts[index];
        bool isDepleted = post.remainingSlots <= 0;

        DecorationImage? bgImage;
        if (post.imageFile != null) {
          bgImage = DecorationImage(
            image: FileImage(post.imageFile!),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.darken,
            ),
          );
        } else if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          bgImage = DecorationImage(
            image: NetworkImage(post.imageUrl!),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.darken,
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: bgImage == null ? Colors.grey.shade900 : null,
              image: bgImage,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ORGANIZATION & FOOD TYPE ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.orgName,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            post.foodType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // --- DATE & TIME SCHEDULE ROW ---
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "${post.date.month}/${post.date.day}/${post.date.year}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "${post.startTime.format(context)} - ${post.endTime.format(context)}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // --- DESCRIPTION ---
                Expanded(
                  child: Text(
                    post.description,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),

                // --- SLOTS & RESERVE BUTTON ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDepleted
                          ? "FULL / NO SLOTS LEFT"
                          : "Slots Left: ${post.remainingSlots}",
                      style: TextStyle(
                        color: isDepleted ? Colors.redAccent : Colors.lightGreenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDepleted ? Colors.grey : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: isDepleted
                          ? null
                          : () {
                              setState(() {
                                if (post.remainingSlots > 0) {
                                  post.remainingSlots--;
                                }
                              });
                            },
                      icon: const Icon(Icons.bookmark_add, size: 16),
                      label: Text(isDepleted ? "Claimed" : "Reserve Slot"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}