import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/order_detail.dart';
import '../services/api_client.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    required this.apiClient,
    required this.orderId,
    this.authToken,
    super.key,
  });

  final ApiClient apiClient;
  final int orderId;
  final String? authToken;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();
  late Future<OrderDetail> orderFuture;
  String? proofBase64;
  String? proofFilename;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    orderFuture = widget.apiClient.fetchOrder(widget.orderId, authToken: widget.authToken);
  }

  @override
  void dispose() {
    paidAmountController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  Future<void> submitPayment() async {
    final amount = double.tryParse(paidAmountController.text.trim()) ?? 0;
    final reference = referenceController.text.trim();

    if (amount <= 0 || reference.isEmpty) {
      showMessage('Paid amount and payment reference are required.');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final order = await widget.apiClient.submitPayment(
        orderId: widget.orderId,
        paidAmount: amount,
        paymentReference: reference,
        authToken: widget.authToken,
        paymentProofBase64: proofBase64,
        paymentProofFilename: proofFilename,
      );
      setState(() {
        orderFuture = Future.value(order);
      });
      showMessage('Payment reference submitted.');
    } catch (error) {
      showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> pickPaymentProof() async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (pickedFile == null) {
      return;
    }

    final bytes = await pickedFile.readAsBytes();

    setState(() {
      proofBase64 = base64Encode(bytes);
      proofFilename = pickedFile.name;
    });

    showMessage('Payment proof selected.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order ${widget.orderId}')),
      body: FutureBuilder<OrderDetail>(
        future: orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Cannot load order: ${snapshot.error}'));
          }

          final order = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order.status}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Total: ${order.total.toStringAsFixed(2)} EGP'),
                      Text('Paid: ${order.paidAmount.toStringAsFixed(2)} EGP'),
                      Text('Remaining: ${order.remainingAmount.toStringAsFixed(2)} EGP'),
                      if (order.paymentReference.isNotEmpty) Text('Reference: ${order.paymentReference}'),
                      if (order.paymentProofUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ApiConfig.absoluteUrl(order.paymentProofUrl),
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Text('Payment proof uploaded.'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery Tracking', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (order.shipment == null) ...[
                        const Text('Shipment is not created yet. Staff will send the order to shipment after payment confirmation.'),
                      ] else ...[
                        Text('Status: ${order.shipment!.status}'),
                        Text('Courier: ${order.shipment!.courierName.isEmpty ? '-' : order.shipment!.courierName}'),
                        Text('Tracking: ${order.shipment!.trackingNumber.isEmpty ? '-' : order.shipment!.trackingNumber}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Submit Payment Reference', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: paidAmountController,
                decoration: const InputDecoration(labelText: 'Paid amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(labelText: 'Wallet / InstaPay reference'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: pickPaymentProof,
                icon: const Icon(Icons.attach_file),
                label: Text(proofFilename == null ? 'Attach Payment Proof' : 'Proof: $proofFilename'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: isSubmitting ? null : submitPayment,
                child: Text(isSubmitting ? 'Submitting...' : 'Submit Payment'),
              ),
              const SizedBox(height: 12),
              const Text('Staff must confirm payment in ERP before shipment.'),
            ],
          );
        },
      ),
    );
  }
}
