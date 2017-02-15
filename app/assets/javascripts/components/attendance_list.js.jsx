var AttendanceList = React.createClass({
  getInitialState: function() {
    return { attendances: [] };
  },

  componentDidMount: function() {
    $.ajax(this.props.url, {
      dataType: 'json'
    }).done(
      function(data) {
        this.setState({ attendances: data });
      }.bind(this)
    )
  },

  attend: function(index, path) {
    $.ajax(path, {
      method: 'PUT',
      dataType: 'text'
    }).done(
      function(data) {
        var attendances = this.state.attendances;
        attendances.splice(index, 1);
        this.setState({ attendances: attendances });
      }.bind(this)
    );
  },

  render: function() {
    var attends = this.state.attendances.map(function(attend, index) {
      return <Attendance name={attend.name}
                         scheduled_at={attend.scheduled_at}
                         late={attend.late}
                         attend={this.attend}
                         index={index}
                         id={attend.id}
                         key={attend.id} />;
    }, this);

    return (
      <div className="row">
        {attends}
      </div>
    );
  }
});

var Attendance = React.createClass({
  attend: function(event) {
    event.preventDefault();
    var mes = this.props.name + 'さん、おはようございます。';
    if (window.confirm(mes)) {
      // TODO: UPDATEを実行し、このAttendanceを削除する
      this.props.attend(this.props.index, event.target.href);
    }
  },

  className: function() {
    return this.props.late ? 'col-sm-3' : 'col-sm-3 late';
  },

  render: function() {
    return (
      <div className={this.className()}>
        <a href={'/attendances/' + this.props.id} onClick={this.attend}>
          <div className="name">{this.props.name}</div>
          <div className="time">{this.props.scheduled_at || '未設定'}</div>
        </a>
      </div>
    );
  }
});
