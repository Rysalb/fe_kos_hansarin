import 'package:flutter/material.dart';
import 'dart:io';

class ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final bool isNetworkImage;
  final String? imagePath;

  const ImagePreviewDialog({
    Key? key,
    required this.imageUrl,
    this.isNetworkImage = true,
    this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: isNetworkImage
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          )
                        : Image.file(
                            File(imagePath!),
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              ),
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 