import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DashboardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardSkeleton(),
          SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: List.generate(9, (index) => _buildMenuCardSkeleton()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Card(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShimmerBox(width: 100, height: 20),
                _buildShimmerBox(width: 100, height: 20),
              ],
            ),
            SizedBox(height: 16),
            _buildShimmerBox(width: double.infinity, height: 20),
            SizedBox(height: 8),
            ...List.generate(4, (index) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _buildShimmerBox(width: double.infinity, height: 40),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCardSkeleton() {
    return Card(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Container(
                width: 60,
                height: 10,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
} 