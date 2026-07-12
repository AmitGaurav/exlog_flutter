import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../bloc/rating_bloc.dart';
import '../../bloc/rating_event.dart';
import '../../bloc/rating_state.dart';

class RateUsPage extends StatefulWidget {
  const RateUsPage({super.key});

  @override
  State<RateUsPage> createState() => _RateUsPageState();
}

class _RateUsPageState extends State<RateUsPage> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RatingBloc>().add(const RatingLoadRequested());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingDescription {
    switch (_rating) {
      case 1:
        return "Poor - We're sorry to hear that";
      case 2:
        return 'Below Average - We can do better';
      case 3:
        return 'Average - Thanks for your feedback';
      case 4:
        return "Good - We're glad you like it!";
      case 5:
        return 'Excellent - Thank you for your support!';
      default:
        return '';
    }
  }

  Color get _ratingColor {
    if (_rating <= 2) return AppColors.expense;
    if (_rating == 3) return const Color(0xFFFF9500);
    if (_rating == 4) return AppColors.primary;
    if (_rating == 5) return AppColors.income;
    return AppColors.textSecondary;
  }

  void _submit(BuildContext context) {
    if (_rating == 0) return;
    context.read<RatingBloc>().add(RatingSubmitRequested(rating: _rating, comment: _commentController.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RatingBloc, RatingState>(
      listenWhen: (prev, cur) => cur.justSubmitted && !prev.justSubmitted || cur.error != prev.error,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        } else if (state.justSubmitted) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Thank You!'),
              content: Text(state.myRating != null && state.myRating!.createdAt != state.myRating!.updatedAt
                  ? 'Your rating has been updated successfully!'
                  : 'Thank you for your feedback! We appreciate your support.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        if (_rating == 0 && state.myRating != null) {
          _rating = state.myRating!.rating;
          _commentController.text = state.myRating!.comment;
        }
        final hasSubmittedBefore = state.myRating != null;

        return Scaffold(
          backgroundColor: AppColors.backgroundGray,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundGray,
            title: const Text('Rate Us', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFFFFCC00), Color(0xFFFF9500)]),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.star, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 12),
                    const Text('Rate ExLog', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Your feedback helps us improve',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (state.myRating != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.income, size: 18),
                          const SizedBox(width: 6),
                          Text('You rated us on ${DateFormat('d MMM yyyy').format(state.myRating!.createdAt)}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < state.myRating!.rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFCC00),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    const Text('How would you rate your experience?',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          iconSize: 38,
                          onPressed: () => setState(() => _rating = star),
                          icon: Icon(
                            star <= _rating ? Icons.star : Icons.star_border,
                            color: star <= _rating ? const Color(0xFFFFCC00) : AppColors.textTertiary,
                          ),
                        );
                      }),
                    ),
                    if (_rating > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_ratingDescription,
                            style: TextStyle(fontSize: 14, color: _ratingColor, fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Tell us more', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        const Text('(Optional)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentController,
                      maxLines: 5,
                      maxLength: 500,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts, suggestions, or what you love about ExLog...',
                        filled: true,
                        fillColor: AppColors.backgroundGray,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _rating == 0 || state.status == RatingStatus.loading ? null : () => _submit(context),
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(hasSubmittedBefore ? 'Update Rating' : 'Submit Rating',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rating > 0 ? AppColors.primary : AppColors.textTertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(15)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Why rate us?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 12),
                    _BenefitItem(Icons.trending_up, 'Help us improve ExLog based on real user feedback'),
                    _BenefitItem(Icons.people_outline, "Guide other users in discovering ExLog's benefits"),
                    _BenefitItem(Icons.lightbulb_outline, 'Share feature requests and ideas for future updates'),
                    _BenefitItem(Icons.favorite_border, 'Show appreciation for the development team'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
