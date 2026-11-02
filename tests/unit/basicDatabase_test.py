import sys
import pytest

sys.path.insert(0, "../../Software Engineering")
import firebaseHelper as db_module

import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime, timezone, timedelta

#allows me to call each function by name instead of firebaseHelper.functionName()
from firebaseHelper import (
    _response,
    UNAUTHORIZED,
    parse_iso_datetime,
    get_database_field,
    edit_database_field,
    add_database_user,
    delete_database_user,
    generate_ListingID,
    add_listing,
    delete_listing,
    edit_listing_location,
    edit_listing,
    _adjust_spots,
    add_reservation,
    remove_reservation,
    get_remaining_spots,
    get_time_until_start,
    get_time_until_end,
    delete_message,
    add_message,
    get_listing_messages,
    get_listing_message_for_user,
    Listing,
    create_listing,
)


@pytest.fixture(autouse=True)
def mock_db(monkeypatch):
    """Automatically replaces the module's `db` client with a MagicMock for every test."""
    mock_client = MagicMock()
    monkeypatch.setattr(db_module, "db", mock_client)
    return mock_client


@pytest.fixture
def disable_db(monkeypatch):
    """Helper fixture to set `db` to None for testing UNAUTHORIZED paths."""
    monkeypatch.setattr(db_module, "db", None)


def test_response_helper():
    assert _response(200, "Success") == {"status": 200, "message": "Success"}


def test_parse_iso_datetime_valid():
    dt = parse_iso_datetime("2026-11-02T14:30:00Z")
    assert dt["message"] == datetime(2026, 11, 2, 14, 30, 0, tzinfo=timezone.utc)


def test_parse_iso_datetime_invalid():
    parse_iso_datetime("not-a-valid-date")["status"] == 400


def test_generate_listing_id():
    res = generate_ListingID(101, "StudentUnion", "2026-11-02T12:00:00Z", "Pizza")
    assert res == "101StudentUnion2026-11-02T12:00:00ZPizza"


def test_get_database_field_success(mock_db):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = {"role": "admin"}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    res = get_database_field("users", "jdoe", "role")
    assert res == {"status": 200, "message": "admin"}


def test_get_database_field_not_found(mock_db):
    mock_doc = MagicMock()
    mock_doc.exists = False
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    res = get_database_field("users", "unknown", "role")
    assert res == {"status": 404, "message": "Document not found"}


def test_get_database_field_exception(mock_db):
    mock_db.collection.side_effect = Exception("Firestore connection error")
    res = get_database_field("users", "jdoe", "role")
    assert res == {"status": 400, "message": "Firestore connection error"}


def test_edit_database_field_unauthorized(disable_db):
    assert edit_database_field("users", "jdoe", "role", "guest") == UNAUTHORIZED


def test_edit_database_field_success(mock_db):
    res = edit_database_field("users", "jdoe", "role", "guest")
    mock_db.collection.assert_called_with("users")
    mock_db.collection.return_value.document.return_value.update.assert_called_with({"role": "guest"})
    assert res == {"status": 200, "message": "OK"}


def test_add_database_user_unauthorized(disable_db):
    assert add_database_user("jdoe", "John", "Doe", "student", "jdoe@example.com") == UNAUTHORIZED


def test_add_database_user_success(mock_db):
    res = add_database_user("jdoe", "John", "Doe", "student", "jdoe@example.com")
    assert res == {"status": 201, "message": "Created"}
    mock_db.collection.assert_called_with("users")
    mock_db.collection.return_value.document.assert_called_with("jdoe")


def test_delete_database_user_success(mock_db):
    mock_doc_ref = mock_db.collection.return_value.document.return_value
    mock_doc_ref.get.return_value.exists = False

    res = delete_database_user("jdoe")
    mock_doc_ref.delete.assert_called_once()
    assert res == {"status": 204, "message": "No Content"}


def test_delete_database_user_conflict(mock_db):
    mock_doc_ref = mock_db.collection.return_value.document.return_value
    mock_doc_ref.get.return_value.exists = True

    res = delete_database_user("jdoe")
    assert res == {"status": 409, "message": "Conflict"}


def test_add_listing_success(mock_db):
    res = add_listing(
        foodType="Bagels",
        description="Fresh assorted bagels",
        quantity=15,
        location="Lobby",
        organizationID=5,
        startTime="2026-11-02T09:00:00Z",
        endTime="2026-11-02T11:00:00Z",
    )
    expected_id = "5Lobby2026-11-02T09:00:00ZBagels"
    assert res == {"status": 200, "message": expected_id}
    mock_db.collection.return_value.document.assert_called_with(expected_id)


def test_add_listing_invalid_datetime(mock_db):
    res = add_listing(
        foodType="Bagels",
        description="Fresh",
        quantity=5,
        location="Lobby",
        organizationID=5,
        startTime="invalid-date",
        endTime="2026-11-02T11:00:00Z",
    )
    assert res["status"] == 400


def test_edit_listing_location_success(mock_db):
    res = edit_listing_location("listing123", "Room 101", 36.12, -97.06)
    assert res == {"status": 200, "message": "OK"}
    mock_db.collection.return_value.document.return_value.update.assert_called_with(
        {"location": "Room 101", "lat": 36.12, "lng": -97.06}
    )


def test_edit_listing_blocks_location_fields(mock_db):
    for protected_field in ("location", "lat", "lng"):
        res = edit_listing("listing123", protected_field, "new_val")
        assert res == {
            "status": 400,
            "message": "use edit_listing_location so coordinates are synced",
        }


def test_edit_listing_valid_field(mock_db):
    res = edit_listing("listing123", "description", "Updated description")
    assert res == {"status": 200, "message": "OK"}


def test_add_reservation_success(mock_db, monkeypatch):
    # Bypass @firestore.transactional wrapper to test reservation logic directly
    monkeypatch.setattr(db_module, "_adjust_spots", lambda tx, ref, delta: 8)
    res = add_reservation("listing123", 2)
    assert res == {"status": 200, "message": 8}


def test_remove_reservation_out_of_range(mock_db, monkeypatch):
    def mock_raise(tx, ref, delta):
        raise ValueError("Reservation amount out of range")

    monkeypatch.setattr(db_module, "_adjust_spots", mock_raise)
    res = remove_reservation("listing123", 50)
    assert res == {"status": 409, "message": "Reservation amount out of range"}


def test_reservation_listing_not_found(mock_db, monkeypatch):
    def mock_raise(tx, ref, delta):
        raise KeyError("Listing not foun")

    monkeypatch.setattr(db_module, "_adjust_spots", mock_raise)
    res = add_reservation("unknown_id", 1)
    assert res == {"status": 404, "message": "'Listing not foun'"}


def test_get_remaining_spots(mock_db):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = {"quantity": 12}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    res = get_remaining_spots("listing123")
    assert res == {"status": 200, "message": 12}


def test_get_time_until_start_future(mock_db):
    future_time = datetime.now(timezone.utc) + timedelta(minutes=25)
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = {"pickupStart": future_time.isoformat()}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    res = get_time_until_start("listing123")
    assert res["status"] == 200
    assert 24 <= res["message"] <= 25


def test_get_time_until_end_past_returns_zero(mock_db):
    past_time = datetime.now(timezone.utc) - timedelta(minutes=15)
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = {"pickupEnd": past_time}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    res = get_time_until_end("listing123")
    assert res == {"status": 200, "message": 0}


def test_add_message_success(mock_db):
    mock_msg_ref = mock_db.collection.return_value.document.return_value
    mock_msg_ref.id = "listing123"

    res = add_message("listing123", True, "user_42", "Is this still available?")
    assert res == {"status": 201, "message": "listing123"}
    mock_msg_ref.set.assert_called_once()


def test_get_listing_messages_success(mock_db):
    mock_doc = MagicMock()
    mock_doc.exists = True
    sample_msgs = [{"userID": "u1", "content": "Hello"}]
    mock_doc.to_dict.return_value = {"messages": sample_msgs}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    res = get_listing_messages("listing123")
    assert res == {"status": 200, "message": sample_msgs}


def test_get_listing_message_for_user(mock_db):
    mock_doc = MagicMock()
    mock_doc.exists = True
    sample_msgs = [
        {"userID": "u1", "content": "Msg 1"},
        {"userID": "u2", "content": "Msg 2"},
        {"userID": "u1", "content": "Msg 3"},
    ]
    mock_doc.to_dict.return_value = {"messages": sample_msgs}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    res = get_listing_message_for_user("listing123", "u1")
    assert res == {
        "status": 200,
        "message": [
            {"userID": "u1", "content": "Msg 1"},
            {"userID": "u1", "content": "Msg 3"},
        ],
    }


def test_listing_dataclass_valid_and_create(mock_db):
    listing = Listing(
        foodType="Sandwiches",
        description="Turkey clubs",
        maxReservations=10,
        location="Room 200",
        organizationID=99,
        startTime="2026-11-02T12:00:00Z",
        endTime="2026-11-02T14:00:00Z",
    )
    res = create_listing(listing)
    assert res["status"] == 200
    assert res["message"] == "99Room 2002026-11-02T12:00:00ZSandwiches"


def test_listing_dataclass_invalid_max_reservations():
    with pytest.raises(ValueError, match="maxReservations must be at least 1"):
        Listing(
            foodType="Sandwiches",
            description="Turkey clubs",
            maxReservations=0,
            location="Room 200",
            organizationID=99,
            startTime="2026-11-02T12:00:00Z",
            endTime="2026-11-02T14:00:00Z",
        )


def test_listing_dataclass_invalid_time_order():
    with pytest.raises(ValueError, match="endTime must be after startTime"):
        Listing(
            foodType="Sandwiches",
            description="Turkey clubs",
            maxReservations=5,
            location="Room 200",
            organizationID=99,
            startTime="2026-11-02T15:00:00Z",
            endTime="2026-11-02T14:00:00Z",
        )