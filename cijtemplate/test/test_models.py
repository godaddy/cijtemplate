from django.test import TestCase
from cijtemplate.models import Question, Choice
from datetime import datetime


class QuestionTests(TestCase):

    def test_has_question_text(self):
        self.assertTrue(hasattr(Question(), 'question_text'))

    def test_has_pub_date(self):
        self.assertTrue(hasattr(Question(), 'pub_date'))

    def test_pub_date_is_datetime(self):
        question = Question(pub_date=datetime.now())
        self.assertIsInstance(question.pub_date, datetime)


class ChoiceTests(TestCase):

    def test_has_choice_text(self):
        self.assertTrue(hasattr(Choice(), 'choice_text'))

    def test_has_votes(self):
        self.assertTrue(hasattr(Choice(), 'votes'))

    def test_question_is_foreign_key(self):
        question = Question(pub_date=datetime.now())
        question.save()
        choice = Choice(question=question)
        self.assertEqual(question, choice.question)
