import 'package:flutter/material.dart';

Widget verticalImageTextButton({
  required String imagePath,
  required String buttonText,
  required VoidCallback onPressed,
  required bool isSelected,
}) {
  return SizedBox(
    width: 150,  
    height: 150, 
    child: ElevatedButton(
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: 80, height: 80), 
          const SizedBox(height: 8),
          Text(
            buttonText, 
            style: TextStyle(color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
