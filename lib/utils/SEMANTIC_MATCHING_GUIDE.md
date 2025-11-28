# Semantic Skill Matching with Hugging Face

## Overview

This document describes the semantic skill matching system that uses Hugging Face sentence-transformers to compute cosine similarity between user skills and required team skills.

## Model

- **Model**: `sentence-transformers/all-MiniLM-L6-v2`
- **Embeddings**: 384-dimensional vectors
- **Algorithm**: Cosine similarity on normalized embeddings
- **API**: Hugging Face Inference API

## How It Works

### 1. **Embedding Generation**

Each skill is converted into a 384-dimensional embedding using the sentence-transformers model:

```
User Skill: "Flutter Development"
  ↓
Embedding: [-0.042, 0.156, ..., 0.203]  (384 dimensions)

Required Skill: "Mobile App Development"
  ↓
Embedding: [-0.051, 0.148, ..., 0.195]  (384 dimensions)
```

### 2. **Similarity Calculation**

Cosine similarity is calculated between embeddings:

```
cosine_similarity = (A · B) / (||A|| × ||B||)

Where:
  A · B = dot product of vectors
  ||A|| = magnitude of vector A
  ||B|| = magnitude of vector B

Result: Score between -1 and 1 (typically 0 to 1 for similarities)
```

### 3. **Match Type Classification**

Each match is classified based on similarity score:

```
Strong Match:  score ≥ 0.8  (highly similar)
Weak Match:    0.1 ≤ score < 0.8  (somewhat similar)
No Match:      score < 0.1  (dissimilar)
```

### 4. **Sorting Strategy**

Results sorted in priority order:

1. **Strong matches** (score ≥ 0.8) - descending by score
2. **Weak matches** (0.1-0.8) - descending by score
3. **No matches** (score < 0.1) - score 0.0

### 5. **Overall Score Calculation**

```
Overall Score = (Σ weighted_scores / required_skills_count) × 100

Where:
  Strong match weight = 1.0 × score
  Weak match weight = 0.5 × score
  No match weight = 0.0

Range: 0-100%
```

## JSON Output Format

```json
{
  "matches": [
    {
      "required_skill": "Flutter Development",
      "best_matching_user_skill": "Flutter Programming",
      "similarity_score": 0.9234,
      "match_type": "strong"
    },
    {
      "required_skill": "Firebase",
      "best_matching_user_skill": "Backend Services",
      "similarity_score": 0.6521,
      "match_type": "weak"
    },
    {
      "required_skill": "Kubernetes",
      "best_matching_user_skill": "Firebase",
      "similarity_score": 0.0832,
      "match_type": "none"
    }
  ],
  "overall_score": 76.85,
  "summary": {
    "strong_matches": 1,
    "weak_matches": 1,
    "no_matches": 1,
    "total_required": 3
  }
}
```

## Usage Example

### Setup

```dart
import 'package:collabverse/utils/semantic_skill_matcher.dart';

// Get your Hugging Face API token from https://huggingface.co/settings/tokens
final String huggingFaceToken = 'hf_your_token_here';
```

### Basic Matching

```dart
final userSkills = ['Flutter', 'Dart', 'Firebase'];
final requiredSkills = ['Mobile Development', 'Backend', 'Cloud Services'];

// Get matching result object
final result = await SemanticSkillMatcher.matchSkills(
  userSkills: userSkills,
  requiredSkills: requiredSkills,
  huggingFaceToken: huggingFaceToken,
);

print('Overall Score: ${result.overallScore}%');
print('Strong Matches: ${result.strongMatches}');
print('Weak Matches: ${result.weakMatches}');
print('No Matches: ${result.noMatches}');
```

### Get JSON Output

```dart
final jsonResult = await SemanticSkillMatcher.matchSkillsJSON(
  userSkills: userSkills,
  requiredSkills: requiredSkills,
  huggingFaceToken: huggingFaceToken,
);

print(jsonResult); // Pure JSON string
```

### Individual Match Details

```dart
for (final match in result.matches) {
  print('''
    Required: ${match.requiredSkill}
    Best Match: ${match.bestMatchingUserSkill}
    Score: ${match.similarityScore.toStringAsFixed(4)}
    Type: ${match.matchType.name}
  ''');
}
```

## Example Scenarios

### Scenario 1: Perfect Skills Match

```dart
userSkills: ['Flutter', 'Dart', 'Firebase'],
requiredSkills: ['Flutter Development', 'Dart Language', 'Firebase Platform'],

Output:
  Match 1: Flutter → Flutter Development (0.9456, strong)
  Match 2: Dart → Dart Language (0.9123, strong)
  Match 3: Firebase → Firebase Platform (0.8876, strong)
  Overall Score: 94.52%
```

### Scenario 2: Partial Skills Match

```dart
userSkills: ['JavaScript', 'React', 'Node.js'],
requiredSkills: ['Mobile Development', 'Web Frontend', 'Database Design'],

Output:
  Match 1: React → Web Frontend (0.8234, strong)
  Match 2: Node.js → Database Design (0.5621, weak)
  Match 3: JavaScript → Mobile Development (0.0945, none)
  Overall Score: 54.32%
```

### Scenario 3: No Skills Match

```dart
userSkills: ['Java', 'Spring Boot', 'PostgreSQL'],
requiredSkills: ['iOS Development', 'Swift', 'Objective-C'],

Output:
  Match 1: Java → iOS Development (0.1234, none)
  Match 2: Spring Boot → Swift (0.0876, none)
  Match 3: PostgreSQL → Objective-C (0.0654, none)
  Overall Score: 3.21%
```

## Performance Considerations

### Embedding Caching

The system caches embeddings to reduce API calls:

```dart
// First call: Makes API request
final result1 = await SemanticSkillMatcher.matchSkills(...);

// Second call with same skills: Uses cache
final result2 = await SemanticSkillMatcher.matchSkills(...);

// Check cache stats
final stats = SemanticSkillMatcher.getCacheStats();
print('Cached: ${stats['cached_embeddings']} embeddings');
print('Memory: ${stats['cache_memory_estimate_kb']} KB');
```

### Clear Cache

```dart
// Clear cache if memory is a concern
SemanticSkillMatcher.clearCache();
```

## API Requirements

### Hugging Face Setup

1. **Create Account**: https://huggingface.co
2. **Generate Token**: https://huggingface.co/settings/tokens
3. **Use in App**:
   ```dart
   final token = 'hf_xxxxxxxxxxxxx';
   ```

### Rate Limits

- Free tier: 30,000 requests/month
- Paid tier: Higher limits
- Estimated cost per match: ~2-5 API calls (depends on unique skills)

## Integration with Discover Page

```dart
// In discover_page.dart
import 'package:collabverse/utils/semantic_skill_matcher.dart';

// When displaying team requests
for (final request in teamRequests) {
  try {
    final matchResult = await SemanticSkillMatcher.matchSkillsJSON(
      userSkills: currentUserProfile.skills,
      requiredSkills: request.requiredSkills,
      huggingFaceToken: huggingFaceToken,
    );

    final decoded = jsonDecode(matchResult);
    final overallScore = decoded['overall_score'];

    // Display the score and matches
    displayTeamCard(request, overallScore, decoded['matches']);
  } catch (e) {
    // Fallback to simple keyword matching
    print('Semantic matching failed: $e');
  }
}
```

## Advantages Over Keyword Matching

### Keyword Matching (Old System)

```
User: "Mobile Development"
Required: "Android App Development"
Match: NONE (no exact keyword match)
Result: 0%
```

### Semantic Matching (New System)

```
User: "Mobile Development"
Required: "Android App Development"
Match: 0.85 (semantically similar)
Result: 85% (Strong Match!)
```

## Error Handling

```dart
try {
  final result = await SemanticSkillMatcher.matchSkills(
    userSkills: userSkills,
    requiredSkills: requiredSkills,
    huggingFaceToken: huggingFaceToken,
  );
} on Exception catch (e) {
  if (e.toString().contains('timeout')) {
    print('API request timed out');
  } else if (e.toString().contains('503')) {
    print('Model is loading, please retry');
  } else {
    print('Error: $e');
  }
}
```

## Testing

```dart
void main() async {
  final userSkills = ['Flutter', 'Firebase', 'Dart'];
  final requiredSkills = ['Mobile App Development', 'Backend Services', 'Programming Language'];

  final result = await SemanticSkillMatcher.matchSkills(
    userSkills: userSkills,
    requiredSkills: requiredSkills,
    huggingFaceToken: 'YOUR_TOKEN',
  );

  print('Test Results:');
  print('Overall Score: ${result.overallScore}%');
  print('JSON Output:\n${result.toJsonString()}');
}
```

## Troubleshooting

### Issue: 503 Model is Loading

**Solution**: The model is loading on first request. Wait a moment and retry.

### Issue: Invalid Token

**Solution**: Check your Hugging Face token from https://huggingface.co/settings/tokens

### Issue: Timeout

**Solution**: Reduce the number of skills being matched or increase timeout duration.

### Issue: High Latency

**Solution**: Enable caching and reuse embeddings for common skills.

## References

- [Hugging Face](https://huggingface.co)
- [Sentence-transformers](https://www.sbert.net)
- [all-MiniLM-L6-v2 Model](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2)
- [Cosine Similarity](https://en.wikipedia.org/wiki/Cosine_similarity)
